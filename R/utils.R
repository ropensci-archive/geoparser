#' @importFrom httr content POST add_headers accept_json status_code
#' @importFrom jsonlite fromJSON
#' @importFrom tidyr unite_
#' @importFrom dplyr "%>%" group_by mutate_ select_ ungroup tbl_df rename_
#' @importFrom lazyeval interp
#' @importFrom utils URLencode

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
  if(nchar(text_input) >= 8000){
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
    results <- lapply(temp$features, unlist)
    results <- lapply(results, as.data.frame)
    results <- lapply(results, t)
    results <- lapply(results, as.data.frame)
    results <- suppressWarnings(dplyr::bind_rows(results))
    # making coordinates numeric
    results$geometry.coordinates2 <- as.numeric(
      as.character(results$geometry.coordinates2))
    results$geometry.coordinates1 <- as.numeric(
      as.character(results$geometry.coordinates1))

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
    results <- function_df(results)

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
  sum(!is.na(vec))
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
  temp <- lapply(df$start, strsplit, "_")
  temp <- lapply(temp, unlist)
  temp <- suppressWarnings(lapply(temp, as.numeric))

  lengths <- unlist(lapply(temp, function_na))

  df <- df[rep(1:nrow(df), lengths), ] %>%
    dplyr::group_by(start) %>%
    dplyr::mutate_(number = lazyeval::interp(quote(1:n()))) %>%
    dplyr::group_by(start)  %>%
    dplyr::mutate_(reference1 = lazyeval::interp(
      quote(
        as.numeric(strsplit(start[1], "_")[[1]][number]))))  %>%
    dplyr::mutate_(reference2 = interp(
      quote(
        as.numeric(strsplit(end[1], "_")[[1]][number])))) %>%
    dplyr::select_(lazyeval::interp(quote(- start))) %>%
    dplyr::select_(lazyeval::interp(quote(- id))) %>%
    dplyr::select_(lazyeval::interp(quote(- number)))  %>%
    dplyr::select_(lazyeval::interp(quote(- end))) %>%
    dplyr::ungroup()

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
