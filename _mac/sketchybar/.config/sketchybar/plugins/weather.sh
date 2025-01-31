#!/bin/zsh
# FORKED FROM: https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-1634025

CITY="Budapest"
CITY=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CITY'))")

# echo "$SENDER" >> /tmp/.debug_sketchbar
if [[ "$SENDER" == "mouse.clicked" ]]; then;
    open "https://www.idokep.hu/idojaras/$CITY"
    exit 0
fi

API_KEY_FILE="$CONFIG_DIR/plugins/sensitive-weather.sh"
if [ -f "$API_KEY_FILE" ]; then
    source "$API_KEY_FILE"
else
    echo "Error: '$API_KEY_FILE' file not found"
    exit 1
fi

# Configuration
# API_KEY="" # SOURCED FROM SECRET FILE

# Simplified weather icon mappings - common conditions only
weather_icons_day=(
    [1000]=  # Sunny/113
    [1003]=  # Partly cloudy/116
    [1006]=  # Cloudy/119
    [1009]=  # Overcast/122
    [1030]=  # Mist/143
    [1063]=  # Patchy rain possible/176
    [1066]=  # Patchy snow possible/179
    [1069]=  # Patchy sleet possible/182
    [1072]=  # Patchy freezing drizzle possible/185
    [1087]=  # Thundery outbreaks possible/200
    [1114]=  # Blowing snow/227
    [1117]=  # Blizzard/230
    [1135]=  # Fog/248
    [1147]=  # Freezing fog/260
    [1150]=  # Patchy light drizzle/263
    [1153]=  # Light drizzle/266
    [1168]=  # Freezing drizzle/281
    [1171]=  # Heavy freezing drizzle/284
    [1180]=  # Patchy light rain/293
    [1183]=  # Light rain/296
    [1186]=  # Moderate rain at times/299
    [1189]=  # Moderate rain/302
    [1192]=  # Heavy rain at times/305
    [1195]=  # Heavy rain/308
    [1198]=  # Light freezing rain/311
    [1201]=  # Moderate or heavy freezing rain/314
    [1204]=  # Light sleet/317
    [1207]=  # Moderate or heavy sleet/320
    [1210]=  # Patchy light snow/323
    [1213]=  # Light snow/326
    [1216]=  # Patchy moderate snow/329
    [1219]=  # Moderate snow/332
    [1222]=  # Patchy heavy snow/335
    [1225]=  # Heavy snow/338
    [1237]=  # Ice pellets/350
    [1240]=  # Light rain shower/353
    [1243]=  # Moderate or heavy rain shower/356
    [1246]=  # Torrential rain shower/359
    [1249]=  # Light sleet showers/362
    [1252]=  # Moderate or heavy sleet showers/365
    [1255]=  # Light snow showers/368
    [1258]=  # Moderate or heavy snow showers/371
    [1261]=  # Light showers of ice pellets/374
    [1264]=  # Moderate or heavy showers of ice pellets/377
    [1273]=  # Patchy light rain with thunder/386
    [1276]=  # Moderate or heavy rain with thunder/389
    [1279]=  # Patchy light snow with thunder/392
    [1282]=  # Moderate or heavy snow with thunder/395
)

weather_icons_night=(
    [1000]=  # Clear/113
    [1003]=  # Partly cloudy/116
    [1006]=  # Cloudy/119
    [1009]=  # Overcast/122
    [1030]=  # Mist/143
    [1063]=  # Patchy rain possible/176
    [1066]=  # Patchy snow possible/179
    [1069]=  # Patchy sleet possible/182
    [1072]=  # Patchy freezing drizzle possible/185
    [1087]=  # Thundery outbreaks possible/200
    [1114]=  # Blowing snow/227
    [1117]=  # Blizzard/230
    [1135]=  # Fog/248
    [1147]=  # Freezing fog/260
    [1150]=  # Patchy light drizzle/263
    [1153]=  # Light drizzle/266
    [1168]=  # Freezing drizzle/281
    [1171]=  # Heavy freezing drizzle/284
    [1180]=  # Patchy light rain/293
    [1183]=  # Light rain/296
    [1186]=  # Moderate rain at times/299
    [1189]=  # Moderate rain/302
    [1192]=  # Heavy rain at times/305
    [1195]=  # Heavy rain/308
    [1198]=  # Light freezing rain/311
    [1201]=  # Moderate or heavy freezing rain/314
    [1204]=  # Light sleet/317
    [1207]=  # Moderate or heavy sleet/320
    [1210]=  # Patchy light snow/323
    [1213]=  # Light snow/326
    [1216]=  # Patchy moderate snow/329
    [1219]=  # Moderate snow/332
    [1222]=  # Patchy heavy snow/335
    [1225]=  # Heavy snow/338
    [1237]=  # Ice pellets/350
    [1240]=  # Light rain shower/353
    [1243]=  # Moderate or heavy rain shower/356
    [1246]=  # Torrential rain shower/359
    [1249]=  # Light sleet showers/362
    [1252]=  # Moderate or heavy sleet showers/365
    [1255]=  # Light snow showers/368
    [1258]=  # Moderate or heavy snow showers/371
    [1261]=  # Light showers of ice pellets/374
    [1264]=  # Moderate or heavy showers of ice pellets/377
    [1273]=  # Patchy light rain with thunder/386
    [1276]=  # Moderate or heavy rain with thunder/389
    [1279]=  # Patchy light snow with thunder/392
    [1282]=  # Moderate or heavy snow with thunder/395
)

# Fetch weather data
data=$(curl -s "http://api.weatherapi.com/v1/current.json?key=$API_KEY&q=$CITY")

# Extract weather information
condition=$(echo $data | jq -r '.current.condition.code')
temp=$(echo $data | jq -r '.current.temp_c')
is_day=$(echo $data | jq -r '.current.is_day')

# Set icon based on time of day
prefix=$([ "$is_day" = "1" ] && echo "day" || echo "night")

[ "$is_day" = "1" ] && icon=$weather_icons_day[$condition] || icon=$weather_icons_night[$condition]

# Update SketchyBar
sketchybar -m --set weather icon="$icon" label="${temp}°C"