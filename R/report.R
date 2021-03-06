# report <- function(x) UseMethod("report")

#' Report summary statistics, diagnostics and date stamping periods of mildly explosive behaviour.
#'
#'
#' @param x An object of class \code{\link[=radf]{radf()}}.
#' @param y An object, which is the output of \code{\link[=mc_cv]{mc_cv()}} or
#' \code{\link[=wb_cv]{wb_cv()}}.
#'
#' @describeIn report Returns a list of summary statistics for the t-statistic
#' and the critical values of the ADF, SADF and GSADF.
#'
#' @examples
#' \donttest{
#' # Simulate bubble processes, compute the t-stat and critical values
#' set.seed(4441)
#' dta <- cbind(sim_dgp1(n = 100), sim_dgp2(n = 100))
#' rfd <- radf(dta)
#' mc <- mc_cv(n = 100)
#'
#' # Report, diagnostics and datestamp (default)
#' report(x = rfd, y = mc)
#' diagnostics(x = rfd, y = mc)
#' datestamp(x = rfd, y = mc)
#'
#' # Diagnostics for 'sadf'
#' diagnostics(x = rfd, y = mc, option = "sadf")
#'
#' # Use rule of thumb to omit periods of explosiveness which are short-lived
#' rot = round(log(NROW(rfd)))
#' datestamp(x = rfd, y = mc, min_duration = rot)
#' }
#' @export
report <- function(x, y) {
  radf_check(x)
  cv_check(y)
  minw_check(x, y)

  ret <- list()
  if (method(y) == "Wild Bootstrap") {
    for (i in seq_along(col_names(x))) {
      df1 <- c(x$adf[i], y$adf_cv[i, ])
      df2 <- c(x$sadf[i], y$sadf_cv[i, ])
      df3 <- c(x$gsadf[i], y$gsadf_cv[i, ])
      df <- data.frame(rbind(df1, df2, df3),
        row.names = c("ADF", "SADF", "GSADF")
      )
      colnames(df) <- c("t-stat", "90%", "95%", "99%")
      ret[[i]] <- df
    }
  } else if (method(y) == "Monte Carlo") {
    for (i in seq_along(col_names(x))) {
      df1 <- c(x$adf[i], y$adf_cv)
      df2 <- c(x$sadf[i], y$sadf_cv)
      df3 <- c(x$gsadf[i], y$gsadf_cv)
      df <- data.frame(rbind(df1, df2, df3),
                       row.names = c("ADF", "SADF", "GSADF"))
      colnames(df) <- c("tstat", "90%", "95%", "99%")
      ret[[i]] <- df
    }
  }

  attr(ret, "minw") <- minw(y)
  attr(ret, "lag") <- lagr(x)
  attr(ret, "method") <- method(y)
  attr(ret, "iter") <- iter(y)

  names(ret) <- col_names(x)
  class(ret) <- append(class(ret), "report")
  ret
}


#' @export
print.report <- function(x, ...) {
  cat(
    "\n", "Recursive Unit Root Testing Summary", "\n",
    "---------------------------------------------", "\n",
    "H0:", "Unit root ", "\n",
    "H1:", "Explosive root", "\n",
    "---------------------------------------------\n",
    "Critical values are generated by:", method(x), "\n",
    "Number of",
    if (method(x) == "Monte Carlo") "iterations:" else "bootstraps:", iter(x), "\n",
    "Minimum window is set to:", minw(x), "\n",
    "Lag is set to:", lagr(x), "\n",
    "---------------------------------------------"
  )
  for (i in seq_along(x)) {
    cat("\n", names(x)[i], "\n")
    print(x[[i]])
  }
}

# diagnostics -------------------------------------------------------------

# diagnostics <- function(x) UseMethod("diagnostics")

#' @inheritParams report
#' @param option Whether to apply the "gsadf" or "sadf" methodology. Default is
#' "gsadf".
#'
#' @describeIn report Finds the series that reject the null for 95\%
#' significance level.
#'
#' @import dplyr
#' @export
diagnostics <- function(x, y, option = c("gsadf", "sadf")) {
  radf_check(x)
  cv_check(y)
  minw_check(x, y)
  option <- match.arg(option)

  if (option == "gsadf") {
    tstat <- x$gsadf
    if (method(y) == "Monte Carlo") {
      cv1 <- y$gsadf_cv[1]
      cv2 <- y$gsadf_cv[2]
      cv3 <- y$gsadf_cv[3]
    } else {
      cv1 <- y$gsadf_cv[, 1]
      cv2 <- y$gsadf_cv[, 2]
      cv3 <- y$gsadf_cv[, 3]
    }
  } else {
    tstat <- x$sadf
    if (method(y) == "Monte Carlo") {
      cv1 <- y$sadf_cv[1]
      cv2 <- y$sadf_cv[2]
      cv3 <- y$sadf_cv[3]
    } else {
      stop("Explosive periods with Wild Bootstraped critical values ",
        "apply only for the option 'gsadf'",
        call. = FALSE
      )
      # cv1 <- y$sadf_cv[, 1]
      # cv2 <- y$sadf_cv[, 2]
      # cv3 <- y$sadf_cv[, 3]
    }
  }

  sig <- case_when(
    tstat < cv1 ~ "Reject",
    tstat >= cv1 & tstat < cv2 ~ "90%",
    tstat >= cv2 & tstat < cv3 ~ "95%",
    tstat >= cv3 ~ "99%"
  )

  if (all(sig == "Reject")) {
    stop("Cannot reject H0, do not proceed for date stamping or plotting",
      call. = FALSE
    )
  }

  cond <- sig == "95%" | sig == "99%"
  proceed <- col_names(x)[cond]

  attr(proceed, "significance") <- sig
  class(proceed) <- "diagnostics"
  attr(proceed, "col_names") <- col_names(x)

  if (is.character0(proceed)) {
    stop("You cannot reject H0 for significance level 95%", call. = FALSE)
  } else {
    proceed
  }
}

is.character0 <- function(ch) {
  is.character(ch) && length(ch) == 0
}

#' @export
print.diagnostics <- function(x, ...) {
  cat(
    "\n",
    "Diagnostics:",
    "\n---------------------------------------------"
  )
  for (i in seq_along(attr(x, "col_names"))) {
    cat("\n", attr(x, "col_names")[i], ":", sep = "")
    if (attr(x, "significance")[i] == "Reject") {
      cat("\n", "Cannot reject H0!")
    } else {
      cat("\n", "Rejects H0 for significance level", attr(x, "significance")[i])
    }
  }
  cat(
    "\n---------------------------------------------",
    "\nProcced for date stampting and plotting for variable(s)",
    deparse(as.vector(x))
  )
}

# datestamp ---------------------------------------------------------------

#' @describeIn report
#'
#' Computes the origination, termination and duration of episodes during which
#' the time series display explosive dynamics.
#'
#' @inheritParams report
#' @param min_duration The minimum duration of an explosive period for it to be
#' reported. Default is 0.
#'
#' @return Returns a list of values for each explosive sub-period, giving the
#' origin and termination dates as well as the number of periods explosive
#' behavior lasts.
#'
#' @details
#' Setting \code{min_duration} allows temporary spikes above the critical value
#' sequence to be removed. Phillips et al. (2015) propose a simple way to remove
#' small periods of explosiveness by a rule of thumb such as "log(T)" or
#' "log(T)/T", where T is the number of observations.
#'
#' @references Phillips, P. C. B., Shi, S., & Yu, J. (2015). Testing for
#' Multiple Bubbles: Historical Episodes of Exuberance and Collapse in the
#' S&P 500. International Economic Review, 56(4), 1043-1078.
#'
#' @importFrom rlang sym
#' @import dplyr
#' @export
#'
datestamp <- function(x, y, option = c("gsadf", "sadf"), min_duration = 0) {
  radf_check(x)
  cv_check(y)
  minw_check(x, y)
  is.nonnegeative.int(min_duration)

  option <- match.arg(option)

  # if (method(y) == "Wild Bootstrap" & option == "sadf") {
  #   stop(message("Explosive periods with Wild Bootstraped critical values",
  #        "apply only for the option 'gsadf'"), call. = FALSE)
  # }

  reps <- diagnostics(x, y, option) %>% match(col_names(x))
  dating <- index(x)[-c(1:(minw(x) + 1 + lagr(x)))]

  ds <- vector("list", length(reps))
  j <- 1
  for (i in reps) {
    if (method(y) == "Monte Carlo") {
      if (option == "gsadf") {
        ds[[j]] <- which(x$bsadf[, i] >
          ifelse(lagr(x) == 0,
            y$badf_cv[, 2],
            y$badf_cv[-c(1:lagr(x)), 2]
          )) +
          minw(x) + lagr(x) + 1
      } else if (option == "sadf") {
        ds[[j]] <- which(x$badf[, i] > y$adf_cv[2]) + minw(x) + 1
      }
    } else if (method(y) == "Wild Bootstrap") {
      if (option == "gsadf") {
        ds[[j]] <- which(x$bsadf[, i] >
          ifelse(lagr(x) == 0,
            y$badf_cv[, 2, i],
            y$badf_cv[-c(1:lagr(x)), 2, i]
          )) +
          minw(x) + lagr(x) + 1
      }
      # else if (option == "sadf") {
      #   ds[[j]] <- which(x$badf[, i] > rep(y$adf_cv[i, 2], NROW(x$badf))) +
      #     minw(x) + 1
      # }
    }
    j <- j + 1
  }
  ds_stamp <- lapply(ds, function(z) z %>%
      stamp() %>%
      filter(!!sym("Duration") >= min_duration) %>%
      as.matrix())

  index_add <- lapply(ds_stamp, function(t) data.frame(
      "Start" = index(x)[t[, 1]],
      "End" = index(x)[t[, 2]],
      "Duration" = t[, 3], row.names = NULL
    ))

  min_reject <- lapply(ds_stamp, function(t) length(t) == 0) %>% unlist()
  res <- index_add[!min_reject]

  if (length(res) == 0) {
    stop("Argument 'min_duration' excludes all the explosive periods",
      call. = FALSE
    )
  }

  names(res) <- col_names(x)[reps][!min_reject]
  res
}

# is.data.frame0 <- function(df) {
#   is.data.frame(df) && nrow(df) == 0
# }

stamp <- function(ds) {
  start <- ds[c(TRUE, diff(ds) != 1)]
  end <- ds[c(diff(ds) != 1, TRUE)]
  end[end - start == 0] <- end[end - start == 0] + 1
  duration <- end - start + 1
  foo <- data.frame("Start" = start, "End" = end, "Duration" = duration)
  foo
}

repn <- function(x) {
  ln <- lapply(x, function(x) NROW(x)) %>% unlist()
  nm <- names(x)
  rep(nm, ln)
}

# Plotting ----------------------------------------------------------------

#' Plotting
#'
#' Plotting method for objects of class \code{\link[=radf]{radf()}}.
#'
#' @inheritParams datestamp
#' @param format_date A character string, optional, determines the format of the
#' date on the plot when the index is of class `Date'.
#' @param breaks_y Optional, determines the breaks on the y-axis.
#' @param breaks_x optional, determines the breaks on the x-axis.
#' @param plot_type For multivariate \code{radf} objects, "multiple" plots the series
#' on multiple plots and "single" superimposes them on a single plot
#' datestamping only the period of explosiveness. Default is "multiple".
#' @param ... Additional graphical arguments passed on to methods. Currently
#' not used.
#'
#' @return A list of ggplot objects.
#'
#' @details
#' \itemize{
#'   \item{\code{breaks_x}: }{A scalar for continuous variable that will feed into
#'   \code{scale_x_date}/ or a date period ("week", "month", "year") or
#'   multiples ("6 months", "2 years") thereof that will feed into
#'   \code{scale_x_continuous}}.
#'   \item{\code{format_date}: }{The format_date and the format in a radf object can
#'   be different. User can specify the format here.}
#'   \item{\code{breaks_y}: }{A scalar for continuous variables which generates breaks
#'   for points at which y gridlines will appear (see \code{scale_y_continuous}).}
#' }
#' @export
#'
#' @import ggplot2
#' @import dplyr
#' @importFrom utils head tail
#' @importFrom graphics plot
#' @importFrom rlang sym
#' @importFrom purrr map
#'
#' @examples
#' \donttest{
#' # Simulate bubble processes, compute t-stat and critical values and summarize
#' set.seed(4441)
#' dta <- cbind(sim_dgp1(n = 100), sim_dgp2(n = 100))
#' rfd <- radf(x = dta)
#' mc <- mc_cv(n = 100)
#' plot(x = rfd, y = mc)
#'
#' # Plot the graphs in one plot
#' library(gridExtra)
#' p1 <- plot(x = rfd, mc)
#' do.call(grid.arrange, c(p1, ncol = 2))
#'
#' #Plot in a single graph
#' plot(x = rfd, y = mc, plot_type = "single")
#' }
plot.radf <- function(x, y, option = c("gsadf", "sadf"), min_duration = 0,
                      plot_type = c("multiple", "single"),
                      breaks_x = NULL, format_date = "%m-%Y",
                      breaks_y = NULL, ...) {
  cv_check(y)
  minw_check(x, y)
  option <- match.arg(option)
  plot_type <- match.arg(plot_type)

  choice <- diagnostics(x, y, option)
  reps <- match(choice, col_names(x))
  dating <- index(x)[-c(1:(minw(x) + 1 + lagr(x)))]
  shade <- datestamp(x, y, option = option, min_duration = min_duration)

  # if (is.null(reps)) {
  #   stop("Plotting is only for the series that reject the Null Hypothesis",
  #     call. = FALSE)
  # }
  if (!missing(breaks_y) & plot_type == "single") {
    warning("Argument 'breaks_y' is redundant when 'plot_type' ",
      "is set to 'single'", call. = FALSE)
  }
  if ((length(choice) == 1 || length(shade) == 1) & plot_type == "single") {
    warning("Argument 'plot_type' should be set to 'multiple' ",
      "when there is only one series to plot", call. = FALSE)
  }

  if (plot_type == "multiple") {
    dat <- vector("list", length(choice))

    for (i in reps) {
      if (option == "gsadf") {
        tstat_dat <- x$bsadf[, i]

        if (method(y) == "Monte Carlo") {
          cv_dat <- ifelse(lagr(x) == 0,
            y$badf_cv[, 2],
            y$badf_cv[-c(1:lagr(x)), 2]
          )
          # if (lagr(x) == 0) {
          #   cv_dat = y$badf_cv[,2]
          # }else{
          #   cv_dat = y$badf_cv[-c(1:lagr(x)), 2]
          #   # cv_dat =  head(y$badf_cv[, 2], -lagr(x), row.names = NULL)
          # }
        } else if (method(y) == "Wild Bootstrap") {
          cv_dat <- ifelse(lagr(x) == 0,
            y$badf_cv[, 2, i],
            y$badf_cv[-c(1:lagr(x)), 2, i]
          )
          # if (lagr(x) == 0) {
          #   cv_dat = y$badf_cv[, 2, i]
          # }else{
          #   cv_dat =  head(y$badf_cv[, 2, i], -lagr(x), row.names = NULL)
          # }
        }
      } else if (option == "sadf") {
        tstat_dat <- x$badf[, i]
        if (method(y) == "Monte Carlo") {
          cv_dat <- rep(y$adf_cv[2], NROW(x$badf))
        }
        # error in dastestamp
        # else if (method(y) == "Wild Bootstrap") {
        #   cv_dat =  rep(y$adf_cv[i, 2], NROW(x$badf))
        # }
      }

      dat[[i]] <- data.frame(
        "dating" = dating,
        "tstat" = tstat_dat,
        "cv" = cv_dat
      )
    }

    h <- vector("list", length(choice))
    j <- 1
    for (i in reps)
      local({
        i <- i
        p <- ggplot(dat[[i]]) +
          geom_line(aes_string(x = "dating", y = "tstat"),
            size = 0.7,
            colour = "blue"
          ) +
          geom_line(aes_string(x = "dating", y = "cv"),
            colour = "red", size = 0.8, linetype = "dashed"
          ) +
          xlab("") + ylab("") + theme_bw() +
          theme(
            axis.line = element_line(colour = "black"),
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(),
            panel.background = element_blank()
          ) +
          ggtitle(choice[j]) +
          geom_rect(
            data = shade[[j]][1:2],
            aes_string(
              xmin = "Start", xmax = "End",
              ymin = -Inf, ymax = +Inf
            ),
            fill = "grey", alpha = 0.25
          ) + {
            if (!is.null(breaks_y)) {
              scale_y_continuous(
                breaks = seq(
                  floor(min(dat[[i]]$tstat)),
                  ceiling(max(dat[[i]]$tstat)),
                  breaks_y
                )
              )
            }
          } + {
            if (!is.null(breaks_x)) {
              if (class(index(x)) == "Date") {
                scale_x_date(date_breaks = breaks_x, date_labels = format_date)
              } else {
                scale_x_continuous(breaks = seq(0, max(index(x)), breaks_x))
              }
        }
        }

        h[[j]] <<- p
        j <<- j + 1
      })
  } else if (plot_type == "single") {
    if (class(index(x)) == "Date") {
      st <- shade %>%
        map(~ .x[1]) %>%
        unlist() %>%
        as.Date(origin = "1970-01-01")
      ed <- shade %>%
        map(~ .x[2]) %>%
        unlist() %>%
        as.Date(origin = "1970-01-01")
    } else {
      st <- shade %>% map(~ .x[1]) %>% unlist()
      ed <- shade %>% map(~ .x[2]) %>% unlist()
    }

    total <- data.frame(
      "key" = shade %>% repn(),
      "Start" = st,
      "End" = ed,
      "Duration" = shade %>% map(~ .x[3]) %>% unlist()
    ) %>% filter(!!sym("Duration") - 1 >= min_duration)

    h <- ggplot(total, aes_string(colour = "key")) +
      geom_segment(aes_string(
        x = "Start", xend = "End",
        y = "key", yend = "key"
      ), size = 7) +
      ylab("") + xlab("") + theme_bw() +
      theme(
        panel.grid.major.y = element_blank(),
        legend.position = "none",
        plot.margin = margin(1, 1, 0, 0, "cm"),
        axis.text.y = element_text(face = "bold", size = 8, hjust = 0)
      )
    if (!is.null(breaks_x)) {
      if (class(index(x)) == "Date") {
        h <- h + scale_x_date(
          date_breaks = breaks_x, date_labels = format_date,
          limits = c(head(index(x), 1), tail(index(x), 1))
        )
      } else {
        h <- h + scale_x_continuous(
          breaks = seq(0, max(index(x)), breaks_x),
          limits = c(minw(x), tail(index(x), 1))
        )
      }
    }
  }

  if (length(h) == 1) {
    return(h[[1]])
  } else {
    return(h)
  }
}
