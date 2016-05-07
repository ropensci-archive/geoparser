context("query")
test_that("query returns a list of data.frames",{
  output <- geoparser_q(text_input = "Paris o Paris")
  expect_is(output, "list")
  expect_is(output$properties, "tbl_df")
  expect_is(output$results, "tbl_df")
})

test_that("no problems if no results",{
  output <- geoparser_q(text_input = "no placename here")
  expect_is(output, "list")
  expect_is(output$properties, "tbl_df")
  expect_is(output$results, "tbl_df")
})

