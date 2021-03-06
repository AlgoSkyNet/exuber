
#' Retrieve/Replace the Index
#'
#' @description  Retrieve or replace the index of a \code{radf} object.
#'
#' @inheritParams report
#' @param ... Further arguments passed to methods.
#' @param value An ordered vector of the same length as the `index' attribute of x.
#'
#' @details If the user does not specify an index during the estimation a
#' pseudo-index is generated which is a sequential numeric series. After the estimation,
#' the user can use \code{index} to retrieve or \code{`index<-`} to replace the index.
#' The index can be either numeric or Date.
#'
#'
#' @export
index <- function(x, ...) {
  UseMethod("index")
}

#' @export
index.default <- function(x, ...) {
  if ("index" %in% names(attributes(x))) {
    attr(x, "index")
  } else {
    seq_len(NROW(x))
  }
}

#' @importFrom stats time
#' @export
index.ts <- function(x, ...) {
    time(x)
}


#' @rdname index
#' @export
`index<-` <- function(x, value) {
  UseMethod("index<-")
}

#' @export
`index<-.radf` <- function(x, value) {
  if (length(index(x)) != length(value)) {
    stop("length of index vectors does not match", call. = FALSE)
  }
  attr(x, "index") <- value
  return(x)
}

# Col_names ---------------------------------------------------------------
#' Retrieve/Set column names
#'
#' Retrieve or set the column names of a class \code{\link[=radf]{radf()}} object. Similar to \code{colnames}, with the only
#' difference that \code{col_names} is for \code{\link[=radf]{radf()}} objects.
#'
#' @inheritParams index
#' @export
#'
#' @examples
#' \donttest{
#' # Simulate bubble processes
#' dta <- cbind(sim_dgp1(n = 100), sim_dgp2(n = 100))
#'
#' rfd <- radf(x = dta)
#' col_names(rfd) <- c("OneBubble", "TwoBubbles")
#' }
col_names <- function(x, ...) {
  UseMethod("col_names")
}

#' @rdname col_names
#' @export
`col_names<-` <- function(x, value) {
  UseMethod("col_names<-")
}

#' @export
col_names.radf <- function(x, ...) {
  attr(x, "col_names")
}

#' @export
`col_names<-.radf` <- function(x, value) {
  if (length(col_names(x)) != length(value)) {
    stop("length of col_names vectors does not match", call. = FALSE)
  }
  attr(x, "col_names") <- value
  x
}
