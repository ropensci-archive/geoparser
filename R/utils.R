#' @importFrom httr content POST add_headers
#' @importFrom jsonlite prettify fromJSON
#' @importFrom tidyr unite_
#' @importFrom dplyr "%>%" group_by mutate_ select_ ungroup tbl_df
#' @importFrom lazyeval interp

# status check
geoparser_check <- function(req) {
  if (req$status_code < 400) return(invisible())
  message <- code_message$message[code_message$code == req$status_code]
  stop("HTTP failure: ", req$status_code, "\n", message, call. = FALSE)
}


# function that checks the query
geoparser_query_check <- function(text_input, key){
  # check key
  if(!is.null(key)){
    if(!is.character(key)){
      stop(call. = FALSE, "Key should be a character.")
    }
  }

  # check text
  if(nchar(text_input) >= 8000){
    stop("The size of text_input should be smaller than 8KB.", .call = FALSE)
    }

}

# parse results
geoparser_parse <- function(req) {
  text <- httr::content(req, as = "text")
  if (identical(text, "")) stop("No output to parse",
                                call. = FALSE)
  temp <- jsonlite::fromJSON(text,
                             simplifyVector = FALSE)

  results <- lapply(temp$features, unlist)
  results <- lapply(results, as.data.frame)
  results <- lapply(results, t)
  results <- lapply(results, as.data.frame)
  results <- suppressWarnings(dplyr::bind_rows(results))
  results$geometry.coordinates2 <- as.numeric(
    as.character(results$geometry.coordinates2))
  results$geometry.coordinates1 <- as.numeric(
    as.character(results$geometry.coordinates1))

  which_ref <- which(grepl("references", names(results)))
  first_ind <- which_ref[which(which_ref %% 2 == 1)]
  results <- unite_(results,
                    "start",
                    names(results)[first_ind])
  which_ref <- which(grepl("references", names(results)))
  results <- unite_(results,
                    "end",
                    names(results)[which_ref])

  results <- function_df(results)

  names(results) <- gsub("properties\\.", "", names(results))

  list(properties = tbl_df(as.data.frame(temp$properties)),
       results = results[, 2:ncol(results)])
}

function_na <- function(vec){
  sum(!is.na(vec))
}

# function for transforming start and end
function_df <- function(df){
  temp <- lapply(df$start, strsplit, "_")
  temp <- lapply(temp, unlist)
  temp <- lapply(temp, as.numeric)

  lengths <- unlist(lapply(temp, function_na))

  df <- df[rep(1:nrow(df), lengths), ] %>%
    group_by(start) %>%
    mutate_(number = interp(quote(1:n()))) %>%
    group_by(start)  %>%
    mutate_(reference1 = interp(
      quote(
        as.numeric(strsplit(start[1], "_")[[1]][number]))))  %>%
    mutate_(reference2 = interp(
      quote(
        as.numeric(strsplit(end[1], "_")[[1]][number])))) %>%
    select_(interp(quote(- start))) %>%
    select_(interp(quote(- end))) %>%
    ungroup()

  df

}

# base URL for all queries
geoparser_url <- function() {
  "https://geoparser.io/api/geoparser/"
}

# get results
geoparser_get <- function(query_par){
  POST(geoparser_url(),
       add_headers(
         "Accept" = "application/json",
         "Authorization" = paste("apiKey", query_par$apiKey),
         "Content-Type" =
           "application/x-www-form-urlencoded; charset=UTF-8"
       ),
       body = paste0("inputText=", URLencode(query_par$inputText))
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
