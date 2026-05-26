# Configuration Helper for PFM Reports
#
# Reads from local ignored "config.yml" at project root, or falls back to
# committed "config.yml.example" to resolve directories and parameters.

library(yaml)
library(rprojroot)

.pfm_config <- local({
  root <- find_rstudio_root_file()
  config_path <- file.path(root, "config.yml")
  example_path <- file.path(root, "config.yml.example")
  
  if (file.exists(config_path)) {
    yaml::read_yaml(config_path)
  } else if (file.exists(example_path)) {
    yaml::read_yaml(example_path)
  } else {
    list()
  }
})

#' Retrieve a user configuration parameter
#'
#' @param key Character. The configuration key to retrieve.
#' @param default Any. Fallback if the key is missing or empty.
#' @return The configuration value, or default.
#' @export
getPfmConfig <- function(key, default = NULL) {
  val <- .pfm_config[[key]]
  if (is.null(val) || (is.character(val) && nchar(as.character(val)) == 0)) {
    return(default)
  }
  return(val)
}
