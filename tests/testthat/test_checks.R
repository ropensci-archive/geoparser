context("checks of parameters")

test_that("the key has to be a character",{
  testthat::skip_on_cran()
  expect_error(geoparser_q(key = 1),
               "Key should be a character")
})

test_that("the text cannot be bigger than 8kB",{
  testthat::skip_on_cran()
  text <- toString(rep("this should get very long", 500))
  expect_error(geoparser_q(text_input = text),
               "The size of text_input should be smaller than")
  expect_error(geoparser_q(text_input = c("lala", text)),
               "The size of text_input should be smaller than")
})
