#' Geoparser query
#'
#' The function calls the geoparser.io API which identifies places mentioned in the input text (in English), disambiguates those places, and returns data about the places found in the text.
#'
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
#'
#' @param text_input A string, whose size must be smaller than 8 KB. See \code{nchar(text_input, type = "bytes")}.
#' @param key Your Geoparser.io key.
#'
#' @details To get an API key, you need to register at \url{https://geoparser.io/pricing.html}.
#' With an hobbyist account, you can make up to 1,000 calls a month to the API. For ease of use, save your API key as an environment variable as described at https://stat545-ubc.github.io/bit003_api-key-env-var.html.
#'
#'The package will conveniently look for your API key using `Sys.getenv("GEOPARSER_KEY")` so if your API key is an environment variable called "GEOPARSER_KEY" you don't need to input it manually.
#'
#' Geoparser.io works best on complete sentences in English. If you have a very short text, such as a partial address like "Auckland New Zealand," you probably want to use a geocoder tool instead of a geoparser. In R, you can use the opencage package for geocoding (\url{https://github.com/ropenscilabs/opencage})!
#'
#' @return A list of 2 data.frames (dplyr tbl_df). The first one is called properties and contains
#' \itemize{
#' \item the apiVersion called apiVersion
#' \item the source of the results
#' \item the id of the query
#' }
#' The second data.frame contains the results and is called results:
#' \itemize{
#' \item properties.country ISO-3166 2-letter country code for the country in which this place is located (see \url{https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2}), or NULL for features outside any sovereign territory.
#' \item properties.confidence A confidence score produced by the place name disambiguation algorithm. Currently returns a placeholder value; subject to change.
#' \item properties.name Best name for the specified location, with a preference for official/short name forms (e.g., "New York" over "NYC," and "California" over "State of California"), which may be different from exactly what appears in the text.
#' \item properties.admin1 A code representing the state/province-level administrative division containing this place. (From GeoNames.org: "Most adm1 are FIPS codes. ISO codes are used for US, CH, BE and ME. UK and Greece are using an additional level between country and fips code. The code '00' stands for general features where no specific adm1 code is defined.")
#' \item properties.type A text description of the geographic feature type — see GeoNames.org for a complete list. Subject to change.
#' \item geometry.type Type of the geographical feature, e.g. "Point".
#' \item longitude Longitude.
#' \item latitude Latitude.
#' \item reference1 Start (index of the first character in the place reference) --  each reference to this place name found in the input text is on one distinct line.
#' \item reference2 End (index of the first character after the place reference) --  each reference to this place name found in the input text is on one distinct line.
#' }
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
