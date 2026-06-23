# Configuration, path, and Run-Group location helpers for pfmreports.
#
# config.yml is a CLI-layer convenience only (ADR 0021): getPfmConfig reads ./config.yml from
# the working directory lazily; the render functions take explicit arguments and never depend
# on a project root. No rprojroot, no load-time file reads.

# Package-private cache for the parsed working-directory config.yml.
.pfmreportsEnv <- new.env(parent = emptyenv())

# Internal: read (and memoise) the working-directory config.yml / config.yml.example.
#' @keywords internal
.readPfmConfig <- function() {
  if (!is.null(.pfmreportsEnv$config)) {
    return(.pfmreportsEnv$config)
  }
  cfg <- list()
  for (p in c("config.yml", "config.yml.example")) {
    if (file.exists(p)) {
      cfg <- tryCatch(yaml::read_yaml(p), error = function(e) list())
      break
    }
  }
  .pfmreportsEnv$config <- cfg
  cfg
}

#' Retrieve a user configuration parameter (CLI convenience)
#'
#' Reads \code{./config.yml} (then \code{./config.yml.example}) from the working directory. This
#' is a convenience for the command-line wrappers; the package render functions take explicit
#' arguments and do not rely on it.
#'
#' @param key Character. The configuration key to retrieve.
#' @param default Any. Fallback if the key is missing or empty.
#' @return The configuration value, or \code{default}.
#' @export
getPfmConfig <- function(key, default = NULL) {
  val <- .readPfmConfig()[[key]]
  if (is.null(val) || (is.character(val) && nchar(as.character(val)) == 0)) {
    return(default)
  }
  val
}

#' Check whether a file path is absolute
#'
#' @param path Character. The path to check.
#' @return Logical. \code{TRUE} if absolute, \code{FALSE} if relative.
#' @export
is_absolute_path <- function(path) {
  if (is.null(path) || nchar(path) == 0) return(FALSE)
  grepl("^[A-Za-z]:", path) || grepl("^/", path) || grepl("^\\\\", path)
}

# Internal: resolve a path against the working directory when relative.
#' @keywords internal
.absPath <- function(path) {
  if (is.null(path) || !nzchar(path) || is_absolute_path(path)) {
    return(path)
  }
  file.path(getwd(), path)
}

#' Directory of the active Run-Group (ADR 0018)
#'
#' Resolves \code{<resultsDir>/<group>}. Relative \code{resultsDir} is taken against the working
#' directory (no project root). Defaults come from options / \code{config.yml}.
#'
#' @param group Character. Run-Group name.
#' @param resultsDir Character. Results Root.
#' @return Directory path.
#' @export
runGroupDir <- function(group = getOption("pfmreports.group", getPfmConfig("group", "exhaustive")),
                        resultsDir = getOption("pfm.resultsDir",
                                               getPfmConfig("resultsDir", "output"))) {
  file.path(.absPath(resultsDir), group)
}

#' Path to a named artifact inside the active Run-Group (ADR 0018)
#'
#' @param name Character. Artifact filename, e.g. \code{"sweep.rds"}, \code{"selected-models.yml"}.
#' @param group,resultsDir See \code{\link{runGroupDir}}.
#' @return File path (which may not yet exist).
#' @export
runGroupArtifact <- function(name,
                             group = getOption("pfmreports.group",
                                               getPfmConfig("group", "exhaustive")),
                             resultsDir = getOption("pfm.resultsDir",
                                                    getPfmConfig("resultsDir", "output"))) {
  file.path(runGroupDir(group, resultsDir), name)
}

#' Parse a \code{--group=<name>} argument from a vector of CLI args
#'
#' @param args Character vector (e.g. \code{commandArgs(trailingOnly = TRUE)}).
#' @return The group name if \code{--group=} is present, else the configured default.
#' @export
parseGroupArg <- function(args) {
  hit <- grep("^--group=", args, value = TRUE)
  if (length(hit)) sub("^--group=", "", hit[[1]]) else getPfmConfig("group", "exhaustive")
}
