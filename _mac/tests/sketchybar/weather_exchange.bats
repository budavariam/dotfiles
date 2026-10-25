#!/usr/bin/env bats
# Tests for the weather.sh (zsh) and exchange-rate.sh (bash) plugins.
# curl/open/sketchybar are PATH stubs; API key files and the rates cache live in $BATS_TEST_TMPDIR.
# exchange-rate.sh uses BSD `date -v` / `stat -f`, so these tests are macOS-only.

load helper

setup() {
  setup_stubs
  # fake CONFIG_DIR with throwaway key files (never the real sensitive-*.sh)
  export CONFIG_DIR="$BATS_TEST_TMPDIR/config"
  mkdir -p "$CONFIG_DIR/plugins"
  echo 'API_KEY=fake-weather-key' > "$CONFIG_DIR/plugins/sensitive-weather.sh"
  echo 'API_KEY_EXCHANGE_RATE=fake-rate-key' > "$CONFIG_DIR/plugins/sensitive-exchange-rate.sh"
  stub_logged open
  unset SENDER
}

# ---------------------------------------------------------------- weather

# weather_curl <city from ipinfo> [ipinfo exit code]
# weatherapi answers come from $RESP_DIR/<q> (falling back to $RESP_DIR/default); URLs are logged.
weather_curl() {
  export RESP_DIR="$BATS_TEST_TMPDIR/resp" STUB_CITY="$1" STUB_CITY_RC="${2:-0}"
  mkdir -p "$RESP_DIR"
  stub_script curl '
case "$*" in
  *ipinfo.io*) printf "%s" "$STUB_CITY"; exit "$STUB_CITY_RC" ;;
esac
echo "$*" >> "$STUB_BIN/curl_api.log"
all="$*"; q="${all##*&q=}"
if [ -f "$RESP_DIR/$q" ]; then cat "$RESP_DIR/$q"
elif [ -f "$RESP_DIR/default" ]; then cat "$RESP_DIR/default"; fi'
}

api_calls() { cat "$STUB_BIN/curl_api.log" 2>/dev/null; }

# resp <q|default> <code> <temp> <is_day>
resp() {
  printf '{"current":{"temp_c":%s,"is_day":%s,"condition":{"code":%s}}}' "$3" "$4" "$2" > "$RESP_DIR/$1"
}

weather() { SENDER="${1:-forced}" run zsh "$PLUGINS/weather.sh"; }

# icon glyphs as raw UTF-8 (private-use codepoints used in weather.sh)
SUN_DAY=$'\xee\x8c\x8d'     # U+E30D, [1000] day
NIGHT_1000=$'\xee\x8c\xab'  # U+E32B, [1000] night
NO_DATA=$'\xf4\x81\x9c\x8e' # U+10170E, fallback icon

@test "weather: day sunny shows day icon, sunny color and temperature" {
  weather_curl Budapest
  resp default 1000 21.4 1
  weather forced
  [ "$status" -eq 0 ]
  sb_has "icon=$SUN_DAY icon.color=0xffFFB74D label=21.4°C label.drawing=on"
}

@test "weather: night uses the night icon and night color" {
  weather_curl Budapest
  resp default 1000 3.0 0
  weather forced
  sb_has "icon=$NIGHT_1000 icon.color=0xff4A90E2 label=3.0°C"
  ! sb_has "icon=$SUN_DAY"
}

@test "weather: rain, snow and thunder map to their colors by day/night" {
  weather_curl Budapest
  resp default 1189 10 1; weather forced; sb_has "icon.color=0xff4FC3F7"; : > "$SB_LOG"
  resp default 1189 10 0; weather forced; sb_has "icon.color=0xff0288D1"; : > "$SB_LOG"
  resp default 1225 -4 1; weather forced; sb_has "icon.color=0xffE0E0E0 label=-4°C"; : > "$SB_LOG"
  resp default 1087 25 0; weather forced; sb_has "icon.color=0xffF9A825"
}

@test "weather: queries weatherapi with the API key and the ipinfo city" {
  weather_curl Szeged
  resp default 1000 20 1
  weather forced
  api_calls | grep -qF "key=fake-weather-key&q=Szeged"
}

@test "weather: city name is URL-encoded" {
  weather_curl "Új Pest"
  resp default 1000 20 1
  weather forced
  api_calls | grep -qF "q=%C3%9Aj%20Pest"
}

@test "weather: city falls back to Budapest when ipinfo fails" {
  weather_curl "" 28
  resp default 1000 20 1
  weather forced
  api_calls | grep -qF "q=Budapest"
}

@test "weather: API error for the city retries with Budapest and uses that data" {
  weather_curl Nowhereville
  echo '{"error":{"code":1006,"message":"No matching location found."}}' > "$RESP_DIR/Nowhereville"
  resp Budapest 1000 17.5 1
  weather forced
  api_calls | grep -qF "q=Nowhereville"
  api_calls | grep -qF "q=Budapest"
  sb_has "label=17.5°C"
  sb_has "icon=$SUN_DAY"
}

@test "weather: no data at all hides the label and shows the fallback icon" {
  weather_curl Budapest
  weather forced
  sb_has "icon=$NO_DATA"
  sb_has "label.drawing=off"
  ! sb_has "label.drawing=on"
}

@test "weather: refreshing events (mouse.entered, system_woke, mouse.exited) update the item" {
  weather_curl Budapest
  resp default 1000 21.4 1
  for s in mouse.entered system_woke mouse.exited mouse.exited.global forced; do
    : > "$SB_LOG"
    weather "$s"
    sb_has "--set weather"
  done
}

@test "weather: mouse.clicked opens idokep for the city and does not touch the bar" {
  weather_curl "Új Pest"
  resp default 1000 21.4 1
  weather mouse.clicked
  [ "$(calls open)" = "https://www.idokep.hu/idojaras/%C3%9Aj%20Pest" ]
  [ ! -s "$SB_LOG" ]
  [ -z "$(api_calls)" ]
}

@test "weather: unknown sender does nothing" {
  weather_curl Budapest
  resp default 1000 21.4 1
  weather something_else
  [ ! -s "$SB_LOG" ]
  [ -z "$(calls open)" ]
}

@test "weather: missing key file aborts with an error and no network call" {
  rm "$CONFIG_DIR/plugins/sensitive-weather.sh"
  weather_curl Budapest
  weather forced
  [ "$status" -eq 1 ]
  [[ "$output" == *"sensitive-weather.sh"*"not found"* ]]
  [ ! -s "$SB_LOG" ]
  [ -z "$(api_calls)" ]
}

# --------------------------------------------------------- exchange-rate

rates_file() { echo "$CACHE_DIR/rates_$1.json"; }
today() { date +%Y%m%d; }
yesterday() { date -v-1d +%Y%m%d; }

# write_rates <yyyymmdd> <EUR> <USD> <GBP>  (HUF-based rates, as the API returns them)
write_rates() {
  mkdir -p "$CACHE_DIR"
  printf '{"result":"success","conversion_rates":{"HUF":1,"EUR":%s,"USD":%s,"GBP":%s}}' "$2" "$3" "$4" > "$(rates_file "$1")"
}

# age_file <file> <hours>: set mtime that many hours (+5 min margin) in the past
age_file() { touch -t "$(date -v-"$2"H -v-5M +%Y%m%d%H%M)" "$1"; }

exchange() { run bash "$PLUGINS/exchange-rate.sh" "$@"; }

setup_rates() {
  export CACHE_DIR="$BATS_TEST_TMPDIR/cache"
}

# 1/0.0025 = 400, 1/0.003 = 333.33, 1/0.002 = 500
@test "exchange: reads today's cache, inverts the HUF rates and truncates to integers" {
  setup_rates
  write_rates "$(today)" 0.0025 0.003 0.002
  exchange --update
  [ "$status" -eq 0 ]
  sb_has "--set currency_euro label=400"
  sb_has "--set currency_usd label=333 "
  sb_has "--set currency_gbp label=500"
  sb_has "--set currency_item label.drawing=off icon.drawing=off"
}

@test "exchange: cache present means no network call" {
  setup_rates
  stub_logged curl '{}'
  write_rates "$(today)" 0.0025 0.003 0.002
  exchange --update
  [ -z "$(calls curl)" ]
}

@test "exchange: without today's cache it fetches with the API key, stores the response and shows it" {
  setup_rates
  stub_logged curl '{"conversion_rates":{"EUR":0.0025,"USD":0.003,"GBP":0.002}}'
  exchange --update
  [ "$(calls curl)" = "-s https://v6.exchangerate-api.com/v6/fake-rate-key/latest/HUF" ]
  [ -s "$(rates_file "$(today)")" ]
  jq -e '.conversion_rates.EUR == 0.0025' "$(rates_file "$(today)")"
  sb_has "--set currency_euro label=400"
}

@test "exchange: fetch is done once per day (second run uses the cache)" {
  setup_rates
  stub_logged curl '{"conversion_rates":{"EUR":0.0025,"USD":0.003,"GBP":0.002}}'
  exchange --update
  exchange --update
  [ "$(calls curl | wc -l | tr -d ' ')" -eq 1 ]
}

@test "exchange: fetch failure and no cache shows the error on currency_item" {
  setup_rates
  stub_script curl 'exit 6'
  exchange --update
  sb_has "--set currency_item label=Failed to fetch rates label.color=0xaadc3545 label.drawing=on icon.drawing=on"
  ! sb_has "currency_euro"
  [ ! -e "$(rates_file "$(today)")" ]
}

@test "exchange: empty API response is not cached" {
  setup_rates
  stub_script curl 'exit 0'
  exchange --update
  [ ! -e "$(rates_file "$(today)")" ]
  sb_has "Failed to fetch rates"
}

@test "exchange: successful fetch deletes cache files older than 7 days, keeps recent ones" {
  setup_rates
  mkdir -p "$CACHE_DIR"
  echo '{}' > "$CACHE_DIR/rates_20200101.json"
  touch -t "$(date -v-10d +%Y%m%d%H%M)" "$CACHE_DIR/rates_20200101.json"
  echo '{}' > "$CACHE_DIR/rates_20200102.json"
  touch -t "$(date -v-3d +%Y%m%d%H%M)" "$CACHE_DIR/rates_20200102.json"
  stub_logged curl '{"conversion_rates":{"EUR":0.0025,"USD":0.003,"GBP":0.002}}'
  exchange --update
  [ ! -e "$CACHE_DIR/rates_20200101.json" ]
  [ -e "$CACHE_DIR/rates_20200102.json" ]
}

@test "exchange: no yesterday cache means white for every currency" {
  setup_rates
  write_rates "$(today)" 0.0025 0.003 0.002
  exchange --update
  sb_has "--set currency_euro label=400 icon.color=0xaaffffff --set currency_usd label=333 icon.color=0xaaffffff --set currency_gbp label=500 icon.color=0xaaffffff"
}

@test "exchange: rate up since yesterday is red, down is green, unchanged is white (fresh fetch)" {
  setup_rates
  # yesterday: EUR 500, USD 333.33, GBP 400  -> today: EUR 400 (down), USD 333.33 (same), GBP 500 (up)
  write_rates "$(yesterday)" 0.002 0.003 0.0025
  write_rates "$(today)" 0.0025 0.003 0.002
  exchange --update
  sb_has "--set currency_euro label=400 icon.color=0xaa28a745"
  sb_has "--set currency_usd label=333 icon.color=0xaaffffff"
  sb_has "--set currency_gbp label=500 icon.color=0xaadc3545"
}

@test "exchange: color fades linearly towards white as the cache ages" {
  setup_rates
  write_rates "$(yesterday)" 0.0025 0.003 0.0025
  write_rates "$(today)" 0.0025 0.003 0.002   # only GBP changed (up -> red)
  age_file "$(rates_file "$(today)")" 1
  exchange --update
  # red 0xdc3545 at 1/3 of the way to white: (231,120,130)
  sb_has "--set currency_gbp label=500 icon.color=0xaae77882"
  : > "$SB_LOG"
  age_file "$(rates_file "$(today)")" 2
  exchange --update
  # 2/3: (243,187,192)
  sb_has "--set currency_gbp label=500 icon.color=0xaaf3bbc0"
}

@test "exchange: color is fully white after FADE_HOURS (3h)" {
  setup_rates
  write_rates "$(yesterday)" 0.0025 0.003 0.0025
  write_rates "$(today)" 0.0025 0.003 0.002
  age_file "$(rates_file "$(today)")" 3
  exchange --update
  sb_has "--set currency_gbp label=500 icon.color=0xaaffffff"
}

@test "exchange: mouse.clicked opens the MNB page without needing key file, cache or bar" {
  rm "$CONFIG_DIR/plugins/sensitive-exchange-rate.sh"
  SENDER=mouse.clicked exchange
  [ "$status" -eq 0 ]
  [ "$(calls open)" = "https://www.mnb.hu/arfolyamok" ]
  [ ! -s "$SB_LOG" ]
}

@test "exchange: mouse.entered refreshes the display" {
  setup_rates
  write_rates "$(today)" 0.0025 0.003 0.002
  SENDER=mouse.entered exchange
  sb_has "--set currency_euro label=400"
}

@test "exchange: plain run (no args, no sender) fetches then displays" {
  setup_rates
  stub_logged curl '{"conversion_rates":{"EUR":0.0025,"USD":0.003,"GBP":0.002}}'
  exchange
  [ "$(calls curl | wc -l | tr -d ' ')" -eq 1 ]
  sb_has "--set currency_gbp label=500"
}

@test "exchange: --test prints the red and green fade tables and does not touch the bar" {
  setup_rates
  exchange --test
  [ "$status" -eq 0 ]
  [[ "$output" == *"Testing RED to WHITE transition:"* ]]
  [[ "$output" == *"Testing GREEN to WHITE transition:"* ]]
  [[ "$output" == *"0xaadc3545"* ]]
  [[ "$output" == *"0xaa28a745"* ]]
  [ ! -s "$SB_LOG" ]
}

@test "exchange: missing key file aborts with an error" {
  setup_rates
  rm "$CONFIG_DIR/plugins/sensitive-exchange-rate.sh"
  exchange --update
  [ "$status" -eq 1 ]
  [[ "$output" == *"sensitive-exchange-rate.sh"*"not found"* ]]
  [ ! -s "$SB_LOG" ]
}
