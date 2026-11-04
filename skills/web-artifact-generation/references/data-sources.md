# Fuel-price, gas-price and FX sources used in this workspace

## Gasoline prices (USD/l)
- **GasPriceRadar** (`https://www.gaspriceradar.com/api/prices/{cc}/?history=true`) — country monthly snapshots (e.g. VN gasoline). Free tier occasionally returns HTTP 402; when blocked, quote values from search snippets and date them.
- **GlobalPetrolPrices** (`https://www.globalpetrolprices.com/benchmark/`, `.../data/`) — monthly world average + country groups (Asia, EU, G20, OECD, OPEC). World gasoline ~1.19 USD/l in 2026.
- **IEA End-Use Prices** (`https://www.iea.org/data-and-statistics/data-tools/end-use-prices-data-explorer`) — global gasoline avg 1.11 USD/l (2024); country retail prices; monthly global oil price stats.

## Exchange-rate / VND basis for VND/L charts
- USD/VND mid-market, 2026-10-28: **25,835 VND/USD** (Trading Economics). Rates shift daily — always state the date you used.

## Quoting a number
- Cite source + date + unit. Do not multiply by an unstated rate.
