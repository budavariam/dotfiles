#!/bin/zsh
# FORKED FROM: https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-1634025

# Color definitions
WHITE=0xaaffffff
SUNNY_DAY="0xffFFB74D"      # Bright orange for sunny day
SUNNY_NIGHT="0xff4A90E2"    # Deep blue for clear night
CLOUDY_DAY="0xff78909C"     # Blue-grey for cloudy day
CLOUDY_NIGHT="0xff455A64"   # Darker blue-grey for cloudy night
RAIN_DAY="0xff4FC3F7"       # Light blue for rain during day
RAIN_NIGHT="0xff0288D1"     # Darker blue for rain during night
SNOW_DAY="0xffE0E0E0"       # Light grey for snow during day
SNOW_NIGHT="0xff9E9E9E"     # Darker grey for snow during night
THUNDER_DAY="0xffFDD835"    # Bright yellow for thunder during day
THUNDER_NIGHT="0xffF9A825"  # Amber for thunder during night
FOG_DAY="0xffB0BEC5"       # Light blue-grey for fog during day
FOG_NIGHT="0xff78909C"     # Darker blue-grey for fog during night

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


# Weather icon colors
weather_colors_day=(
    [1000]="$SUNNY_DAY"     # Sunny
    [1003]="$CLOUDY_DAY"    # Partly cloudy
    [1006]="$CLOUDY_DAY"    # Cloudy
    [1009]="$CLOUDY_DAY"    # Overcast
    [1030]="$FOG_DAY"       # Mist
    [1063]="$RAIN_DAY"      # Patchy rain
    [1066]="$SNOW_DAY"      # Patchy snow
    [1069]="$SNOW_DAY"      # Patchy sleet
    [1072]="$SNOW_DAY"      # Patchy freezing drizzle
    [1087]="$THUNDER_DAY"   # Thundery outbreaks
    [1114]="$SNOW_DAY"      # Blowing snow
    [1117]="$SNOW_DAY"      # Blizzard
    [1135]="$FOG_DAY"       # Fog
    [1147]="$FOG_DAY"       # Freezing fog
    [1150]="$RAIN_DAY"      # Light drizzle
    [1153]="$RAIN_DAY"      # Light drizzle
    [1168]="$SNOW_DAY"      # Freezing drizzle
    [1171]="$SNOW_DAY"      # Heavy freezing drizzle
    [1180]="$RAIN_DAY"      # Light rain
    [1183]="$RAIN_DAY"      # Light rain
    [1186]="$RAIN_DAY"      # Moderate rain
    [1189]="$RAIN_DAY"      # Moderate rain
    [1192]="$RAIN_DAY"      # Heavy rain
    [1195]="$RAIN_DAY"      # Heavy rain
    [1198]="$SNOW_DAY"      # Light freezing rain
    [1201]="$SNOW_DAY"      # Heavy freezing rain
    [1204]="$SNOW_DAY"      # Light sleet
    [1207]="$SNOW_DAY"      # Heavy sleet
    [1210]="$SNOW_DAY"      # Light snow
    [1213]="$SNOW_DAY"      # Light snow
    [1216]="$SNOW_DAY"      # Moderate snow
    [1219]="$SNOW_DAY"      # Moderate snow
    [1222]="$SNOW_DAY"      # Heavy snow
    [1225]="$SNOW_DAY"      # Heavy snow
    [1237]="$SNOW_DAY"      # Ice pellets
    [1240]="$RAIN_DAY"      # Light rain shower
    [1243]="$RAIN_DAY"      # Heavy rain shower
    [1246]="$RAIN_DAY"      # Torrential rain
    [1249]="$SNOW_DAY"      # Light sleet showers
    [1252]="$SNOW_DAY"      # Heavy sleet showers
    [1255]="$SNOW_DAY"      # Light snow showers
    [1258]="$SNOW_DAY"      # Heavy snow showers
    [1261]="$SNOW_DAY"      # Light ice pellets
    [1264]="$SNOW_DAY"      # Heavy ice pellets
    [1273]="$THUNDER_DAY"   # Light rain with thunder
    [1276]="$THUNDER_DAY"   # Heavy rain with thunder
    [1279]="$THUNDER_DAY"   # Light snow with thunder
    [1282]="$THUNDER_DAY"   # Heavy snow with thunder
)

weather_colors_night=(
    [1000]="$SUNNY_NIGHT"     # Clear
    [1003]="$CLOUDY_NIGHT"    # Partly cloudy
    [1006]="$CLOUDY_NIGHT"    # Cloudy
    [1009]="$CLOUDY_NIGHT"    # Overcast
    [1030]="$FOG_NIGHT"       # Mist
    [1063]="$RAIN_NIGHT"      # Patchy rain
    [1066]="$SNOW_NIGHT"      # Patchy snow
    [1069]="$SNOW_NIGHT"      # Patchy sleet
    [1072]="$SNOW_NIGHT"      # Patchy freezing drizzle
    [1087]="$THUNDER_NIGHT"   # Thundery outbreaks
    [1114]="$SNOW_NIGHT"      # Blowing snow
    [1117]="$SNOW_NIGHT"      # Blizzard
    [1135]="$FOG_NIGHT"       # Fog
    [1147]="$FOG_NIGHT"       # Freezing fog
    [1150]="$RAIN_NIGHT"      # Light drizzle
    [1153]="$RAIN_NIGHT"      # Light drizzle
    [1168]="$SNOW_NIGHT"      # Freezing drizzle
    [1171]="$SNOW_NIGHT"      # Heavy freezing drizzle
    [1180]="$RAIN_NIGHT"      # Light rain
    [1183]="$RAIN_NIGHT"      # Light rain
    [1186]="$RAIN_NIGHT"      # Moderate rain
    [1189]="$RAIN_NIGHT"      # Moderate rain
    [1192]="$RAIN_NIGHT"      # Heavy rain
    [1195]="$RAIN_NIGHT"      # Heavy rain
    [1198]="$SNOW_NIGHT"      # Light freezing rain
    [1201]="$SNOW_NIGHT"      # Heavy freezing rain
    [1204]="$SNOW_NIGHT"      # Light sleet
    [1207]="$SNOW_NIGHT"      # Heavy sleet
    [1210]="$SNOW_NIGHT"      # Light snow
    [1213]="$SNOW_NIGHT"      # Light snow
    [1216]="$SNOW_NIGHT"      # Moderate snow
    [1219]="$SNOW_NIGHT"      # Moderate snow
    [1222]="$SNOW_NIGHT"      # Heavy snow
    [1225]="$SNOW_NIGHT"      # Heavy snow
    [1237]="$SNOW_NIGHT"      # Ice pellets
    [1240]="$RAIN_NIGHT"      # Light rain shower
    [1243]="$RAIN_NIGHT"      # Heavy rain shower
    [1246]="$RAIN_NIGHT"      # Torrential rain
    [1249]="$SNOW_NIGHT"      # Light sleet showers
    [1252]="$SNOW_NIGHT"      # Heavy sleet showers
    [1255]="$SNOW_NIGHT"      # Light snow showers
    [1258]="$SNOW_NIGHT"      # Heavy snow showers
    [1261]="$SNOW_NIGHT"      # Light ice pellets
    [1264]="$SNOW_NIGHT"      # Heavy ice pellets
    [1273]="$THUNDER_NIGHT"   # Light rain with thunder
    [1276]="$THUNDER_NIGHT"   # Heavy rain with thunder
    [1279]="$THUNDER_NIGHT"   # Light snow with thunder
    [1282]="$THUNDER_NIGHT"   # Heavy snow with thunder
)


CITY=$(curl -s --connect-timeout 3 https://ipinfo.io/city)
if [[ $? -ne 0 ]]; then
    CITY="Budapest"
fi
CITY=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$CITY'))")

if [[ "$SENDER" == "mouse.clicked" ]]; then
    open "https://www.idokep.hu/idojaras/$CITY"
    return 0
fi

# Fetch weather data
data=$(curl -s "http://api.weatherapi.com/v1/current.json?key=$API_KEY&q=$CITY")
data_error=$(echo $data | jq -r '.error')
if [[ -z "$data" || "$data" == "null" || -n $data_error ]]; then
    CITY="Budapest"
    data=$(curl -s "http://api.weatherapi.com/v1/current.json?key=$API_KEY&q=$CITY")
fi

label_drawing=on
icon_color=$WHITE
if [[ -n $data ]]; then
    condition=$(echo $data | jq -r '.current.condition.code')
    temp=$(echo $data | jq -r '.current.temp_c')
    is_day=$(echo $data | jq -r '.current.is_day')

    # Set icon based on time of day
    prefix=$([ "$is_day" = "1" ] && echo "day" || echo "night")

    [ "$is_day" = "1" ] && icon=$weather_icons_day[$condition] || icon=$weather_icons_night[$condition]

    if [ "$is_day" = "1" ]; then
        icon=$weather_icons_day[$condition]
        icon_color=$weather_colors_day[$condition]
    else
        icon=$weather_icons_night[$condition]
        icon_color=$weather_colors_night[$condition]
    fi
    
else
    icon="􁜎"
    label_drawing="off"
fi

# Update SketchyBar with icon and color separately
sketchybar -m --set weather \
    icon="$icon" \
    icon.color="$icon_color" \
    label="${temp}°C" \
    label.drawing="$label_drawing"