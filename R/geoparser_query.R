#' Geoparser query
#'
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#'
#' @param text_input A string, whose size must be smaller than 8 KB. See \code{nchar(text_input, type = "bytes")}.
#' @param key Your Geoparser.io key
#'
#' @details To get an API key, you need to register at \url{https://geoparser.io/pricing.html}.
#' With an hobbyist account, you can make up to 1,000 calls a month to the API.
#'
#' @return A data.frame (dplyr tbl_df)
#' @export
#'
#' @examples geoparser_q(text_input = "I was born in Vannes but I live in Barcelona.")
geoparser_q <- function(text_input,
                        key=geoparser_key()){

  # check arguments
  geoparser_query_check(text_input, key)

  # res
  temp <- geoparser_get(query_par = list(inputText = URLencode(text_input),
                                        apiKey = key))

  # check message
  geoparser_check(temp)

  # done!
  geoparser_parse(temp)



}
