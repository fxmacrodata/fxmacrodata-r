#' fxmacrodata: client for the FXMacroData API
#'
#' Functions are named after the endpoint they call and return a data frame
#' wherever the endpoint returns a series. Everything else the API sent back
#' (source, coverage, pagination) is kept in the `"meta"` attribute; read it
#' with [fxmd_meta()].
#'
#' USD endpoints work without an API key. For other currencies set the
#' `FXMACRODATA_API_KEY` environment variable or call [fxmd_set_key()].
#'
#' @keywords internal
"_PACKAGE"

.fxmd <- new.env(parent = emptyenv())

#' Set the API key for this session
#'
#' The key is sent in the `X-API-Key` header and never in the URL. Without a
#' call to this function the key is read from the `FXMACRODATA_API_KEY`
#' environment variable.
#'
#' @param key API key, or `NULL` to forget a key set earlier.
#' @return The previous key, invisibly.
#' @export
#' @examples
#' fxmd_set_key("my-key")
#' fxmd_set_key(NULL)
fxmd_set_key <- function(key) {
  previous <- .fxmd$key
  .fxmd$key <- key
  invisible(previous)
}

fxmd_key <- function() {
  key <- .fxmd$key
  if (is.null(key)) {
    key <- Sys.getenv("FXMACRODATA_API_KEY", unset = "")
  }
  if (nzchar(key)) key else NULL
}

fxmd_base_url <- function() {
  getOption("fxmacrodata.base_url", "https://api.fxmacrodata.com")
}

# Fill `{name}` placeholders in an endpoint template, escaping each value.
fxmd_path <- function(template, ...) {
  values <- list(...)
  for (name in names(values)) {
    value <- values[[name]]
    if (!is.character(value) || length(value) != 1L || is.na(value) || !nzchar(value)) {
      stop("`", name, "` must be a single non-empty string.", call. = FALSE)
    }
    template <- sub(
      paste0("{", name, "}"),
      utils::URLencode(value, reserved = TRUE),
      template,
      fixed = TRUE
    )
  }
  template
}

# Query values as the API expects them: NULL dropped, logicals lower-case,
# vectors comma-separated, dates in ISO form.
fxmd_query <- function(params) {
  params <- params[!vapply(params, is.null, logical(1))]
  if (length(params) && (is.null(names(params)) || any(!nzchar(names(params))))) {
    stop("Query parameters must be named, for example `start_date = \"2024-01-01\"`.", call. = FALSE)
  }
  lapply(params, function(value) {
    if (is.logical(value)) {
      value <- tolower(as.character(value))
    } else if (inherits(value, c("Date", "POSIXt"))) {
      value <- format(value, if (inherits(value, "Date")) "%Y-%m-%d" else "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    }
    paste(value, collapse = ",")
  })
}

fxmd_error_body <- function(resp) {
  body <- tryCatch(httr2::resp_body_json(resp), error = function(e) NULL)
  detail <- body$detail
  if (is.null(detail)) {
    return(NULL)
  }
  if (is.character(detail)) {
    return(detail)
  }
  if (is.list(detail) && !is.null(detail$message)) {
    return(as.character(detail$message))
  }
  jsonlite::toJSON(detail, auto_unbox = TRUE)
}

#' Call any FXMacroData endpoint
#'
#' The endpoint functions in this package are thin wrappers around this one.
#' Use it directly for a route that has no wrapper yet.
#'
#' @param path Path beginning with `/v1/`.
#' @param query Named list of query parameters. `NULL` entries are dropped.
#' @param body Optional list sent as a JSON body, which makes the request a POST.
#' @return The parsed response. A series under `data` becomes a data frame.
#' @export
#' @examples
#' \dontrun{
#' fxmd_request("/v1/ping")
#' }
fxmd_request <- function(path, query = list(), body = NULL) {
  req <- httr2::request(fxmd_base_url())
  req <- httr2::req_url_path_append(req, path)
  req <- httr2::req_url_query(req, !!!fxmd_query(query))
  req <- httr2::req_user_agent(req, paste0("fxmacrodata-r/", utils::packageVersion("fxmacrodata")))
  req <- httr2::req_headers(req, Accept = "application/json")
  key <- fxmd_key()
  if (!is.null(key)) {
    req <- httr2::req_headers(req, `X-API-Key` = key, .redact = "X-API-Key")
  }
  if (!is.null(body)) {
    req <- httr2::req_body_json(req, body, auto_unbox = TRUE)
  }
  req <- httr2::req_retry(req, max_tries = 3)
  req <- httr2::req_error(req, body = fxmd_error_body)
  resp <- httr2::req_perform(req)
  jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = TRUE)
}

# Columns that hold calendar dates arrive as "YYYY-MM-DD" strings.
fxmd_parse_dates <- function(df) {
  for (name in names(df)) {
    column <- df[[name]]
    if (is.character(column) && (name == "date" || endsWith(name, "_date"))) {
      present <- column[!is.na(column)]
      if (length(present) && all(grepl("^\\d{4}-\\d{2}-\\d{2}$", present))) {
        df[[name]] <- as.Date(column)
      }
    }
  }
  df
}

# Return the series under `field` as a data frame, with the rest of the
# response attached as metadata.
fxmd_series <- function(result, field = "data") {
  series <- result[[field]]
  if (is.null(series) || (is.list(series) && !is.data.frame(series) && length(series) == 0L)) {
    series <- data.frame()
  }
  if (!is.data.frame(series)) {
    return(result)
  }
  series <- fxmd_parse_dates(series)
  attr(series, "meta") <- result[setdiff(names(result), field)]
  series
}

#' Response metadata
#'
#' Everything the API returned alongside a series: source, coverage,
#' pagination and, on the free tier, the access window.
#'
#' @param x A data frame returned by one of the endpoint functions.
#' @return A named list, empty if `x` carries no metadata.
#' @export
#' @examples
#' \dontrun{
#' rates <- fxmd_announcements("USD", "policy_rate")
#' fxmd_meta(rates)$source
#' }
fxmd_meta <- function(x) {
  meta <- attr(x, "meta", exact = TRUE)
  if (is.null(meta)) list() else meta
}
