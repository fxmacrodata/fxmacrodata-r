json_response <- function(body, status = 200L) {
  httr2::response(
    status_code = status,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(body)
  )
}

announcements_body <- paste0(
  '{"currency":"USD","indicator":"policy_rate","source":"Federal Reserve",',
  '"data":[{"date":"2026-09-16","val":4.0,"previous_date":"2026-07-29","note":null},',
  '{"date":"2026-07-29","val":3.75,"previous_date":null,"note":null}]}'
)

test_that("a series comes back as a data frame with parsed dates and metadata", {
  httr2::local_mocked_responses(function(req) json_response(announcements_body))
  rates <- fxmd_announcements("USD", "policy_rate")

  expect_s3_class(rates, "data.frame")
  expect_equal(nrow(rates), 2L)
  expect_s3_class(rates$date, "Date")
  expect_s3_class(rates$previous_date, "Date")
  expect_equal(rates$val, c(4.0, 3.75))
  expect_equal(fxmd_meta(rates)$source, "Federal Reserve")
  expect_null(fxmd_meta(rates)$data)
})

test_that("an empty series is an empty data frame, not an error", {
  httr2::local_mocked_responses(function(req) json_response('{"currency":"USD","data":[]}'))
  result <- fxmd_cot("USD")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_equal(fxmd_meta(result)$currency, "USD")
})

test_that("path and query are built as the API expects", {
  seen <- NULL
  httr2::local_mocked_responses(function(req) {
    seen <<- req
    json_response('{"data":[]}')
  })
  fxmd_announcements(
    "USD", "inflation",
    start_date = as.Date("2025-01-01"), official_only = TRUE, limit = 5, end_date = NULL
  )

  url <- httr2::url_parse(seen$url)
  expect_equal(url$path, "/v1/announcements/USD/inflation")
  expect_equal(url$query, list(start_date = "2025-01-01", official_only = "true", limit = "5"))
})

test_that("the key travels in the header and never in the URL", {
  seen <- NULL
  httr2::local_mocked_responses(function(req) {
    seen <<- req
    json_response('{"data":[]}')
  })
  previous <- fxmd_set_key("test-key-value")
  on.exit(fxmd_set_key(previous))
  fxmd_forex("EUR", "USD")

  skip_if_not("req_get_headers" %in% getNamespaceExports("httr2"))
  headers <- httr2::req_get_headers(seen, redacted = "reveal")
  expect_equal(headers[["X-API-Key"]], "test-key-value")
  expect_false(grepl("test-key-value", seen$url, fixed = TRUE))
  expect_false(grepl("api_key", seen$url, fixed = TRUE))
})

test_that("no key header is sent when no key is configured", {
  seen <- NULL
  httr2::local_mocked_responses(function(req) {
    seen <<- req
    json_response('{"status":"ok"}')
  })
  previous <- fxmd_set_key(NULL)
  on.exit(fxmd_set_key(previous))
  withr_env <- Sys.getenv("FXMACRODATA_API_KEY", unset = NA)
  Sys.unsetenv("FXMACRODATA_API_KEY")
  on.exit(if (!is.na(withr_env)) Sys.setenv(FXMACRODATA_API_KEY = withr_env), add = TRUE)

  expect_equal(fxmd_ping()$status, "ok")
  expect_null(seen$headers[["X-API-Key"]])
})

test_that("an API error surfaces the server's explanation", {
  httr2::local_mocked_responses(function(req) {
    json_response('{"detail":"A subscription is required for EUR."}', status = 401L)
  })
  expect_error(fxmd_announcements("EUR", "policy_rate"), "subscription is required")
})

test_that("path arguments are validated and escaped", {
  expect_error(fxmd_announcements("", "policy_rate"), "currency")
  expect_error(fxmd_announcements(c("USD", "EUR"), "policy_rate"), "currency")
  expect_equal(fxmd_path("/v1/calendar/{currency}", currency = "a/b"), "/v1/calendar/a%2Fb")
})

test_that("unnamed query parameters are rejected", {
  expect_error(fxmd_calendar("USD", "2025-01-01"), "must be named")
})

test_that("a POST body is sent as JSON", {
  seen <- NULL
  httr2::local_mocked_responses(function(req) {
    seen <<- req
    json_response('{"series":[],"data":[]}')
  })
  fxmd_research_panel(
    series = list(list(currency = "USD", indicator = "inflation")),
    decision_times = "2026-01-01T00:00:00Z",
    start_date = as.Date("2025-01-01"),
    end_date = "2026-01-01"
  )
  expect_equal(seen$body$data$start_date, "2025-01-01")
  expect_equal(seen$body$data$series[[1]]$indicator, "inflation")
  expect_equal(httr2::url_parse(seen$url)$path, "/v1/research/panel")
})
