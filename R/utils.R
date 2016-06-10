#' @importFrom httr content POST add_headers accept_json status_code
#' @importFrom jsonlite fromJSON
#' @importFrom tidyr unite_
#' @importFrom dplyr "%>%" group_by mutate_ select_ ungroup tbl_df rename_ arrange_
#' @importFrom lazyeval interp
#' @importFrom utils URLencode
#' @importFrom purrr map map_df map_dbl safely
#' @importFrom stringr str_split
#' @importFrom digest digest

# status check
#' @noRd
geoparser_check <- function(req) {
  status <- httr::status_code(req)
  if (status < 400) return(invisible())
  stop("HTTP failure: ", status, call. = FALSE)
}


# function that checks the query
#' @noRd
geoparser_query_check <- function(text_input, key){
  # check key
  if(!is.null(key)){
    if(!is.character(key)){
      stop(call. = FALSE, "Key should be a character.")
    }
  }

  # check text
  if(any(nchar(text_input) >= 8192)){
    stop("The size of text_input should be smaller than 8KB.", call. = FALSE)
    }

}

# parse results
#' @noRd
geoparser_parse <- function(req) {
  text <- httr::content(req, as = "text",
                        encoding = "UTF-8")
  if (identical(text, "")) stop("No output to parse",
                                call. = FALSE)
  temp <- jsonlite::fromJSON(text,
                             simplifyVector = FALSE)
  # if we have something to process
  # getting from the raw output to a nice data.frame
  if(length(temp$features) != 0){

    results <- purrr::map(temp$features, unlist)
    results <- suppressWarnings(purrr::map(results, as.data.frame))
    results <- purrr::map(results, t)
    results <- suppressWarnings(purrr::map_df(results, as.data.frame))
    # making coordinates numeric
    results <- results %>%
      mutate_(geometry.coordinates2 = lazyeval::interp(
        ~ as.numeric(as.character(geometry.coordinates2))))
    results <- results %>%
      mutate_(geometry.coordinates1 = lazyeval::interp(
        ~ as.numeric(as.character(geometry.coordinates1))))

    # start modification of references to possibly multiple
    # occurrences of words
    # for this I first put all start and end references together
    # separated by "_"
    which_ref <- which(grepl("references", names(results)))
    first_ind <- which_ref[which(which_ref %% 2 == 1)]
    results <- tidyr::unite_(results,
                             "start",
                             names(results)[first_ind])
    which_ref <- which(grepl("references", names(results)))
    results <- tidyr::unite_(results,
                             "end",
                             names(results)[which_ref])
    # end of the transformation for having 1 line per occurence
    results <- suppressMessages(function_df(results))

    # make names nicer by erasing the "properties." they have
    # at the beginning
    names(results) <- gsub("properties\\.", "", names(results))
    results <- results[, 3:ncol(results)]
  }else{
    results <- dplyr::tbl_df(data.frame(NULL))
  }


  list(properties = dplyr::tbl_df(as.data.frame(temp$properties)),
       results = results)
}

#' @noRd
function_na <- function(vec){
  # sep by _
  temp <- stringr::str_split(vec, "_")[[1]]
  # to numeric, warnings when NA
  temp <- suppressWarnings(as.numeric(temp))
  # count number of not NA
  sum(!is.na(temp))
}

# for CRAN
start <- NULL

# function for transforming start and end
# This was needed because when a word is found several times,
# I want a line per occurence instead of one line with
# the starts and ends of all occurences in one cell.
# I think it's better for further processing.
#' @noRd
function_df <- function(df){
  # arrange else lengths do not correspond to df
  df <- arrange_(df, ~ start)
  lengths <- dplyr::select_(df, "start")
  lengths <- split(lengths, lengths$start)
  lengths <-  purrr::map_dbl(lengths, function_na)

  df <- df[rep(1:nrow(df), lengths), ]
  df <- dplyr::group_by(df, start)
  df <- dplyr::mutate_(df, number = lazyeval::interp(quote(1:n())))
  df <- dplyr::group_by(df, start)
  df <- dplyr::mutate_(df, reference1 = lazyeval::interp(
      quote(
        as.numeric(strsplit(start[1], "_")[[1]][number]))))
  df <- dplyr::mutate_(df, reference2 = interp(
      df <- quote(
        as.numeric(strsplit(end[1], "_")[[1]][number]))))
  df <- dplyr::select_(df, lazyeval::interp(quote(- start)))
  df <- dplyr::select_(df, lazyeval::interp(quote(- id)))
  df <- dplyr::select_(df, lazyeval::interp(quote(- number)))
  df <- dplyr::select_(df, lazyeval::interp(quote(- end)))
  df <- dplyr::ungroup(df)

  df %>%
    dplyr::rename_(longitude =
                     lazyeval::interp(quote(geometry.coordinates1))) %>%
    dplyr::rename_(latitude = lazyeval::interp(quote(geometry.coordinates2)))

}

# base URL for all queries
#' @noRd
geoparser_url <- function() {
  "https://geoparser.io/api/geoparser/"
}

# get results
#' @noRd
geoparser_get <- function(query_par){
  httr::POST(geoparser_url(),
             httr::accept_json(),
             httr::add_headers(
               "Authorization" = paste("apiKey", query_par$apiKey),
               "Content-Type" =
                 "application/x-www-form-urlencoded; charset=UTF-8"
             ),
             body = paste0("inputText=",
                           utils::URLencode(query_par$inputText))
  )
}
# get results
#' @noRd
geoparser_get_safe <- purrr::safely(geoparser_get)

#' Retrieve Geoparser.io API key
#'
#' A Geoparser.io API Key
#' Looks in env var \code{GEOPARSER_KEY}
#'
#' @keywords internal
#' @export
geoparser_key <- function(quiet = TRUE) {
  pat <- Sys.getenv("GEOPARSER_KEY")
  if (identical(pat, ""))  {
    return(NULL)
  }
  if (!quiet) {
    message("Using Geoparser.io API Key from envvar GEOPARSER_KEY")
  }
  return(pat)
}

#############
# vectorizing
#' @noRd
total <- function(text, key){
  # res
  temp <- geoparser_get_safe(query_par = list(inputText = URLencode(text),
                                         apiKey = key))
  if(!is.null(temp$error)){
    message(paste0("The API call failed, the error message is ", temp$error))
    return(NULL)
  }else{
    temp <- temp$result
  }
  # check message
  geoparser_check(temp)

  # parse
  parsed <- geoparser_parse(temp)
  # add text for future reference
  parsed[["results"]] <- mutate_(parsed[["results"]],
                                 text_md5 = ~digest::digest(text, algo = "md5"))

  parsed[["properties"]] <- mutate_(parsed[["properties"]],
                                 text_md5 = ~digest::digest(text, algo = "md5"))

  # done!
  parsed

}
