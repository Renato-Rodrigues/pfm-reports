test_that("sigStars maps p-values to stars", {
  expect_equal(sigStars(c(0.0005, 0.005, 0.03, 0.08, 0.5, NA)),
               c("***", "**", "*", ".", "", ""))
})

test_that("is_absolute_path detects absolute paths cross-platform", {
  expect_true(is_absolute_path("C:/x/y"))
  expect_true(is_absolute_path("/x/y"))
  expect_false(is_absolute_path("x/y"))
  expect_false(is_absolute_path(""))
})

test_that("%||% returns the left value unless NULL", {
  expect_equal(3 %||% 4, 3)
  expect_equal(NULL %||% 4, 4)
})

test_that("runGroupArtifact joins resultsDir/group/name", {
  p <- runGroupArtifact("sweep.rds", group = "exhaustive", resultsDir = "/tmp/out")
  expect_match(p, "exhaustive")
  expect_match(p, "sweep\\.rds$")
})

test_that("parseGroupArg reads --group= or falls back", {
  expect_equal(parseGroupArg(c("--group=guided", "--x")), "guided")
  expect_equal(parseGroupArg(c("--x", "--y")), getPfmConfig("group", "exhaustive"))
})

test_that("clean_term_plain formats interactions and FE", {
  expect_equal(clean_term_plain("a_x_b"), "a × b")
  expect_match(clean_term_plain("regionFEEUR"), "^FE: ")
})

test_that("capAtP99 caps and counts", {
  r <- capAtP99(c(1, 2, 3, 100), probs = 0.75)
  expect_true(r$nAbove >= 1)
  expect_true(max(r$values) <= r$cap)
})

test_that("theme_report returns a ggplot theme", {
  expect_s3_class(theme_report(), "theme")
})

test_that("render templates ship in the installed package", {
  for (nm in c("selection", "model-selection", "results-adoption", "robustness", "subnational")) {
    f <- system.file("rmd", paste0(nm, ".Rmd"), package = "pfmreports")
    expect_true(nzchar(f) && file.exists(f), info = nm)
  }
})
