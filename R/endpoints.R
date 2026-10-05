# One function per API route. Each names its path template literally so the
# set can be checked against the OpenAPI contract.

#' Shared arguments
#'
#' @param currency Three-letter currency code, for example `"USD"`.
#' @param indicator Indicator slug, for example `"policy_rate"` or `"inflation"`.
#'   [fxmd_data_catalogue()] lists the slugs available for a currency.
#' @param base,quote Currency codes of the pair, for example `"EUR"` and `"USD"`.
#' @param ... Query parameters for the endpoint, named as in the
#'   [API reference](https://fxmacrodata.com/documentation/reference), for
#'   example `start_date = "2024-01-01"`, `end_date`, `limit`. Dates may be
#'   `Date` objects.
#' @return A data frame with one row per observation; see [fxmd_meta()] for the
#'   rest of the response.
#' @name fxmd_args
#' @keywords internal
NULL

# ---- Announcements -------------------------------------------------------

#' Macroeconomic announcements
#'
#' `fxmd_announcements()` returns the release history of one indicator.
#' `fxmd_latest_announcements()` returns the most recent value of every
#' indicator for a currency. `fxmd_announcement_changes()` polls for releases
#' published since a cursor.
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
#' @examples
#' \dontrun{
#' fxmd_announcements("USD", "policy_rate")
#' fxmd_announcements("USD", "inflation", start_date = as.Date("2025-01-01"))
#' fxmd_latest_announcements("USD")
#' }
fxmd_announcements <- function(currency, indicator, ...) {
  path <- fxmd_path("/v1/announcements/{currency}/{indicator}", currency = currency, indicator = indicator)
  fxmd_series(fxmd_request(path, list(...)))
}

#' @rdname fxmd_announcements
#' @export
fxmd_latest_announcements <- function(currency) {
  fxmd_series(fxmd_request(fxmd_path("/v1/announcements/{currency}/latest", currency = currency)))
}

#' @rdname fxmd_announcements
#' @export
fxmd_announcement_changes <- function(...) {
  fxmd_series(fxmd_request("/v1/announcements/changes", list(...)))
}

#' Release calendar
#'
#' Scheduled and past release times for a currency's indicators.
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
#' @examples
#' \dontrun{
#' fxmd_calendar("USD")
#' }
fxmd_calendar <- function(currency, ...) {
  fxmd_series(fxmd_request(fxmd_path("/v1/calendar/{currency}", currency = currency), list(...)))
}

#' Data catalogue
#'
#' Every indicator published for a currency, with units and frequency.
#'
#' @inheritParams fxmd_args
#' @return A named list with one entry per indicator slug.
#' @export
#' @examples
#' \dontrun{
#' names(fxmd_data_catalogue("USD"))
#' }
fxmd_data_catalogue <- function(currency, ...) {
  fxmd_request(fxmd_path("/v1/data_catalogue/{currency}", currency = currency), list(...))
}

#' Central-bank press releases
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
fxmd_press_releases <- function(currency, ...) {
  fxmd_series(fxmd_request(fxmd_path("/v1/press-releases/{currency}", currency = currency), list(...)))
}

#' Point-in-time research panel
#'
#' Several series aligned to a set of decision times, as they were known at
#' each one.
#'
#' @param series List of series, each a list with `currency` and `indicator`.
#' @param decision_times Character vector of ISO 8601 timestamps.
#' @param start_date,end_date Bounds of the panel, as `Date` or `"YYYY-MM-DD"`.
#' @param ... Further request fields, for example `availability`.
#' @inherit fxmd_args return
#' @export
fxmd_research_panel <- function(series, decision_times, start_date, end_date, ...) {
  body <- c(
    list(
      series = series,
      decision_times = as.list(decision_times),
      start_date = format(start_date),
      end_date = format(end_date)
    ),
    list(...)
  )
  fxmd_series(fxmd_request("/v1/research/panel", body = body))
}

# ---- Forecasts -----------------------------------------------------------

#' Predictions
#'
#' `fxmd_predictions()` returns forecasts for one indicator.
#' `fxmd_prediction_coverage()` reports which indicators have forecasts, for
#' every currency or for one.
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
fxmd_predictions <- function(currency, indicator, ...) {
  path <- fxmd_path("/v1/predictions/{currency}/{indicator}", currency = currency, indicator = indicator)
  fxmd_series(fxmd_request(path, list(...)))
}

#' @rdname fxmd_predictions
#' @return `fxmd_prediction_coverage()` returns a list.
#' @export
fxmd_prediction_coverage <- function(currency = NULL) {
  if (is.null(currency)) {
    return(fxmd_request("/v1/predictions/coverage"))
  }
  fxmd_request(fxmd_path("/v1/predictions/coverage/{currency}", currency = currency))
}

# ---- FX ------------------------------------------------------------------

#' FX rates
#'
#' `fxmd_forex()` returns daily spot rates. `fxmd_fx_reference_rates()` returns
#' official central-bank reference fixings, `fxmd_fx_intraday_reference_rates()`
#' their intraday publications, and `fxmd_fx_session_rates()` rates sampled at
#' trading-session boundaries.
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
#' @examples
#' \dontrun{
#' fxmd_forex("EUR", "USD", start_date = "2025-01-01")
#' }
fxmd_forex <- function(base, quote, ...) {
  fxmd_series(fxmd_request(fxmd_path("/v1/forex/{base}/{quote}", base = base, quote = quote), list(...)))
}

#' @rdname fxmd_forex
#' @export
fxmd_fx_reference_rates <- function(base, quote, ...) {
  path <- fxmd_path("/v1/fx/reference-rates/{base}/{quote}", base = base, quote = quote)
  fxmd_series(fxmd_request(path, list(...)))
}

#' @rdname fxmd_forex
#' @export
fxmd_fx_intraday_reference_rates <- function(base, quote, ...) {
  path <- fxmd_path("/v1/fx/intraday-reference-rates/{base}/{quote}", base = base, quote = quote)
  fxmd_series(fxmd_request(path, list(...)))
}

#' @rdname fxmd_forex
#' @param session Trading session: `"sydney"`, `"tokyo"`, `"london"` or `"new_york"`.
#' @export
fxmd_fx_session_rates <- function(base, quote, session, ...) {
  path <- fxmd_path("/v1/fx/session-rates/{base}/{quote}", base = base, quote = quote)
  fxmd_series(fxmd_request(path, c(list(session = session), list(...))))
}

#' FX reference-rate sources
#'
#' `fxmd_fx_sources()` lists the publishers of official reference rates.
#' `fxmd_fx_source_universe()` lists the pairs each one publishes.
#'
#' @inheritParams fxmd_args
#' @return A data frame.
#' @export
fxmd_fx_sources <- function() {
  fxmd_series(fxmd_request("/v1/fx/sources"), "sources")
}

#' @rdname fxmd_fx_sources
#' @export
fxmd_fx_source_universe <- function(...) {
  fxmd_series(fxmd_request("/v1/fx/source-universe", list(...)))
}

#' FX market sessions
#'
#' Which trading sessions are open, and their overlaps.
#'
#' @inheritParams fxmd_args
#' @return A list with `sessions` and `overlaps` data frames.
#' @export
fxmd_market_sessions <- function(...) {
  fxmd_request("/v1/market_sessions", list(...))
}

# ---- Rates ---------------------------------------------------------------

#' Interest-rate differentials
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
fxmd_rate_differentials <- function(base, quote, ...) {
  path <- fxmd_path("/v1/rate_differentials/{base}/{quote}", base = base, quote = quote)
  fxmd_series(fxmd_request(path, list(...)))
}

#' Yield curves
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
fxmd_curves <- function(currency, ...) {
  fxmd_series(fxmd_request(fxmd_path("/v1/curves/{currency}", currency = currency), list(...)))
}

#' Financial prices
#'
#' Bond and money-market prices from official sources.
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
fxmd_financial_prices <- function(currency, ...) {
  fxmd_series(fxmd_request(fxmd_path("/v1/financial_prices/{currency}", currency = currency), list(...)))
}

# ---- Positioning, commodities, sentiment ---------------------------------

#' Commitments of Traders positioning
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
#' @examples
#' \dontrun{
#' fxmd_cot("USD")
#' }
fxmd_cot <- function(currency, ...) {
  fxmd_series(fxmd_request(fxmd_path("/v1/cot/{currency}", currency = currency), list(...)))
}

#' Commodity prices
#'
#' `fxmd_commodities()` returns the history of one commodity series.
#' `fxmd_latest_commodities()` returns the latest value of each.
#'
#' @param indicator Commodity slug, for example `"gold"`.
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
fxmd_commodities <- function(indicator, ...) {
  fxmd_series(fxmd_request(fxmd_path("/v1/commodities/{indicator}", indicator = indicator), list(...)))
}

#' @rdname fxmd_commodities
#' @export
fxmd_latest_commodities <- function() {
  fxmd_series(fxmd_request("/v1/commodities/latest"))
}

#' Risk sentiment
#'
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
fxmd_risk_sentiment <- function(...) {
  fxmd_series(fxmd_request("/v1/risk_sentiment", list(...)))
}

#' Currency factors
#'
#' @param factor Factor slug.
#' @inheritParams fxmd_args
#' @inherit fxmd_args return
#' @export
fxmd_factor <- function(currency, factor, ...) {
  path <- fxmd_path("/v1/factors/{currency}/{factor}", currency = currency, factor = factor)
  fxmd_series(fxmd_request(path, list(...)))
}

# ---- Service -------------------------------------------------------------

#' Service status
#'
#' @return A list with the service status.
#' @export
#' @examples
#' \dontrun{
#' fxmd_ping()
#' }
fxmd_ping <- function() {
  fxmd_request("/v1/ping")
}

#' @rdname fxmd_ping
#' @export
fxmd_health <- function() {
  fxmd_request("/v1/health")
}
