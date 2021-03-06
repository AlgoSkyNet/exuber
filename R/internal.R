# citation ----------------------------------------------------------------

# .onAttach <-
#   function(libname, pkgname) {
#     packageStartupMessage("\nPlease cite as:\n",
#                           " Vasilopoulos, Pavlidis and Spavound (2018): exuber\n",
#                           " R package version 0.1.0. https://CRAN.R-project.org/package=exuber \n")
#   }

# Check if a character string is a Date -----------------------------------

findDates <- function(strings) {
  pattern1 <- "[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]"
  pattern2 <- "[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]"
  pattern3 <- "[0-9][0-9]/[0-9][0-9][0-9][0-9]/[0-9][0-9]"
  pattern4 <- "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"

  tdBool <- grepl(pattern1, strings) | grepl(pattern2, strings) |
    grepl(pattern3, strings) | grepl(pattern4, strings)
  return(tdBool)
}

# Testing arguments ------------------------------------------------------

is.positive.int <- function(arg) {
  level <- deparse(substitute(arg))
  if (arg != round(arg) || arg <= 0L) {
    stop(sprintf(
      "Argument '%s' should be a positive integer",
      level
    ), call. = FALSE)
  }
}

is.nonnegeative.int <- function(arg) {
  level <- deparse(substitute(arg))
  if (arg != round(arg) | arg < 0L) {
    stop(sprintf(
      "Argument '%s' should be a non-negative integer",
      level
    ), call. = FALSE)
  }
}

is.between <- function(x, arg1, arg2) {
  level <- deparse(substitute(x))
  if (x < arg1 | x > arg2) {
    stop(sprintf(
      "Argument '%s' should be a be between '%d' and '%d'",
      level, arg1, arg2
    ), call. = FALSE)
  }
}

# radf and cv specific ----------------------------------------------------

radf_check <- function(x) {
  if (!inherits(x, "radf")) {
    stop("Argument 'x' should be of class 'radf'", call. = FALSE)
  }
}

cv_check <- function(y) {
  if (!inherits(y, "cv")) {
    stop("Argument 'y' should be of class 'cv'", call. = FALSE)
  }
}

minw_check <- function(x, y) {
  if (minw(x) != minw(y)) {
    stop("The critical values should have the same minumum", "
         window with the t-statistics!", call. = FALSE)
  }
}

# Rest --------------------------------------------------------------------

minw <- function(x) {
  attr(x, "minw")
}

lagr <- function(x, ...) {
  attr(x, "lag")
}

method <- function(y) {
  attr(y, "method")
}

iter <- function(y) {
  attr(y, "iter")
}
