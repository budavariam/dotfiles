#!/usr/bin/env bash

COLOR=$WHITE
SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"

cnf_spotify_name=(
    icon=""
    icon.color="$COLOR"
    icon.padding_left="${INNER_PADDINGS}"
    icon.padding_right=1
    label.padding_left=5
    label.padding_right="${INNER_PADDINGS}"
    label.padding_left=0
    label.drawing=off
    label.max_chars=54
    background.padding_left=0
    background.border_color=0x77ADADAD
    background.border_color="$COLOR"
    popup.horizontal=on
    popup.align=center
    popup.background.image.scale=0.5
    script="$PLUGIN_DIR/spotify.sh"
)
cnf_spotify_back=(
    icon="􀊎"
    icon.padding_left=5
    icon.padding_right=5
    label.drawing=off
    script="$PLUGIN_DIR/spotify.sh"
)
cnf_spotify_next=(
    icon="􀊐"
    icon.padding_left=5
    icon.padding_right=10
    label.drawing=off
    script="$PLUGIN_DIR/spotify.sh"
)
cnf_spotify_shuffle=(
    icon=􀊝
    icon.highlight_color=0xff1DB954
    icon.padding_left=5
    icon.padding_right=5
    label.drawing=off
    script="$PLUGIN_DIR/spotify.sh"
)
cnf_spotify_play=(
    icon="􀊄"
    icon.padding_left=5
    icon.padding_right=5
    updates=on
    label.drawing=off
    script="$PLUGIN_DIR/spotify.sh"
)

cnf_spotify_bracket=(
    label.color="$COLOR"                        
    background.drawing=on                           
    background.corner_radius="$CORNER_RADIUS"       
    background.padding_right=5                      
    background.border_color="$WHITE"                
    background.color="$BAR_COLOR"                   
    background.padding_left=5
)

sketchybar  \
            --add       event           spotify_change $SPOTIFY_EVENT       \
                                                                            \
            --add       item            spotify.name left                   \
            --set       spotify.name    "${cnf_spotify_name[@]}"            \
            --subscribe spotify.name    mouse.clicked                       \
                                                                            \
            --add       item            spotify.back popup.spotify.name     \
            --set       spotify.back    "${cnf_spotify_back[@]}"            \
            --subscribe spotify.back    mouse.clicked                       \
                                                                            \
            --add       item            spotify.play popup.spotify.name     \
            --set       spotify.play    "${cnf_spotify_play[@]}"            \
            --subscribe spotify.play    mouse.clicked spotify_change        \
                                                                            \
            --add       item            spotify.next popup.spotify.name     \
            --set       spotify.next    "${cnf_spotify_next[@]}"            \
            --subscribe spotify.next    mouse.clicked                       \
                                                                            \
            --add       item            spotify.shuffle popup.spotify.name  \
            --set       spotify.shuffle "${cnf_spotify_shuffle[@]}"         \
            --subscribe spotify.shuffle mouse.clicked                       \
                                                                            \
            --add       bracket         b_spotify                           \
                                        spotify.name                        \
                                        spotify.back                        \
                                        spotify.play                        \
                                        spotify.next                        \
                                        spotify.shuffle                     \
                                        spotify.repeat                      \
            --set       b_spotify  "${cnf_spotify_bracket[@]}"              \
