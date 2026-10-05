# Quickstart: latest US policy rate, release calendar and catalogue.
# USD works without a key; set FXMACRODATA_API_KEY for other currencies.
library(fxmacrodata)

rates <- fxmd_announcements("USD", "policy_rate")
latest <- rates[1, ]
cat(sprintf("USD policy rate: %s on %s\n", latest$val, latest$date))
cat(sprintf("Source: %s\n", fxmd_meta(rates)$source))

calendar <- fxmd_calendar("USD")
cat(sprintf("USD calendar: %d releases\n", nrow(calendar)))

catalogue <- fxmd_data_catalogue("USD")
cat(sprintf("USD catalogue: %d indicators\n", length(catalogue)))
