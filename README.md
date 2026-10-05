# FXMacroData SDK for R

R client for the [FXMacroData API](https://fxmacrodata.com/documentation/reference?utm_source=github&utm_medium=referral&utm_campaign=fxmacrodata-r&utm_content=readme): macroeconomic announcements with release timestamps, release calendars, FX reference rates, rate differentials, yield curves, COT positioning and commodities, sourced from central banks and statistics offices across 22 currencies.

Series come back as data frames, with date columns already parsed.

USD endpoints work without an API key. Other currencies need a [subscription](https://fxmacrodata.com/subscribe?utm_source=github&utm_medium=referral&utm_campaign=fxmacrodata-r&utm_content=subscribe).

## Install

```r
# install.packages("remotes")
remotes::install_github("fxmacrodata/fxmacrodata-r")
```

## Quickstart

```r
library(fxmacrodata)

rates <- fxmd_announcements("USD", "policy_rate")
head(rates[, c("date", "val")])

# Everything else the API returned: source, coverage, pagination
fxmd_meta(rates)$source

# Query parameters are passed by name; dates can be Date objects
cpi <- fxmd_announcements("USD", "inflation", start_date = as.Date("2025-01-01"))

calendar <- fxmd_calendar("USD")
names(fxmd_data_catalogue("USD"))
```

The same calls are in `inst/examples/quickstart.R`.

## Authentication

Set `FXMACRODATA_API_KEY` in your environment (for example in `~/.Renviron`), or call `fxmd_set_key("...")` once per session. The key is sent in the `X-API-Key` header and never in the URL.

## Functions

| Function | Endpoint |
| --- | --- |
| `fxmd_announcements(currency, indicator, ...)` | `/v1/announcements/{currency}/{indicator}` |
| `fxmd_latest_announcements(currency)` | `/v1/announcements/{currency}/latest` |
| `fxmd_announcement_changes(...)` | `/v1/announcements/changes` |
| `fxmd_calendar(currency, ...)` | `/v1/calendar/{currency}` |
| `fxmd_data_catalogue(currency, ...)` | `/v1/data_catalogue/{currency}` |
| `fxmd_press_releases(currency, ...)` | `/v1/press-releases/{currency}` |
| `fxmd_predictions(currency, indicator, ...)` | `/v1/predictions/{currency}/{indicator}` |
| `fxmd_prediction_coverage(currency = NULL)` | `/v1/predictions/coverage`, `/v1/predictions/coverage/{currency}` |
| `fxmd_forex(base, quote, ...)` | `/v1/forex/{base}/{quote}` |
| `fxmd_fx_reference_rates(base, quote, ...)` | `/v1/fx/reference-rates/{base}/{quote}` |
| `fxmd_fx_intraday_reference_rates(base, quote, ...)` | `/v1/fx/intraday-reference-rates/{base}/{quote}` |
| `fxmd_fx_session_rates(base, quote, session, ...)` | `/v1/fx/session-rates/{base}/{quote}` |
| `fxmd_fx_sources()` | `/v1/fx/sources` |
| `fxmd_fx_source_universe(...)` | `/v1/fx/source-universe` |
| `fxmd_market_sessions(...)` | `/v1/market_sessions` |
| `fxmd_rate_differentials(base, quote, ...)` | `/v1/rate_differentials/{base}/{quote}` |
| `fxmd_curves(currency, ...)` | `/v1/curves/{currency}` |
| `fxmd_financial_prices(currency, ...)` | `/v1/financial_prices/{currency}` |
| `fxmd_cot(currency, ...)` | `/v1/cot/{currency}` |
| `fxmd_commodities(indicator, ...)` | `/v1/commodities/{indicator}` |
| `fxmd_latest_commodities()` | `/v1/commodities/latest` |
| `fxmd_risk_sentiment(...)` | `/v1/risk_sentiment` |
| `fxmd_factor(currency, factor, ...)` | `/v1/factors/{currency}/{factor}` |
| `fxmd_research_panel(series, decision_times, start_date, end_date, ...)` | `POST /v1/research/panel` |
| `fxmd_ping()`, `fxmd_health()` | `/v1/ping`, `/v1/health` |

`...` takes the endpoint's query parameters as documented in the [API reference](https://fxmacrodata.com/documentation/reference?utm_source=github&utm_medium=referral&utm_campaign=fxmacrodata-r&utm_content=docs). For a route without a wrapper, `fxmd_request("/v1/...", query = list(...))` calls it directly.

## Errors

A failed request raises an R error carrying the HTTP status and the API's own explanation. Rate-limited and transient server errors are retried up to three times.

## Licence

MIT
