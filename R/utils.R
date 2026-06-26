#' Null-coalescing operator
#'
#' Returns \code{a} when it is non-NULL, otherwise \code{b}. Available to report templates via
#' \code{library(pfmreports)}.
#'
#' @param a,b Values; \code{a} is returned unless it is \code{NULL}.
#' @return \code{a} if non-NULL, else \code{b}.
#' @name nullCoalesce
#' @aliases %||%
#' @export
`%||%` <- function(a, b) if (is.null(a)) b else a
