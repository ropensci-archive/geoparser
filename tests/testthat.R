library(testthat)
library(geoparser)

if (identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  test_check("geoparser")
}
