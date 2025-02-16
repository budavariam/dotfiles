#!/usr/bin/env bash

COLOR=$WHITE
SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"

sketchybar --add item spotify.name left                                     \
           --subscribe spotify.name    mouse.clicked                        \
           --add event  spotify_change $SPOTIFY_EVENT                       \
           --set spotify.name label.padding_left=5                          \
                 icon=♫                                                     \
                 background.padding_left=0                                  \
                 icon.padding_left="${INNER_PADDINGS}"                      \
                 icon.padding_right="${INNER_PADDINGS}"                     \
                 label.padding_right="${INNER_PADDINGS}"                    \
                 label.padding_left=0                                       \
                 script="$PLUGIN_DIR/spotify.sh"                            \
                 background.border_color=0x77ADADAD                         \
                 label.drawing=off                                          \
                 label.max_chars=54                                         \
                 icon.color="$COLOR"                                        \
                 background.border_color="$COLOR"                           \
                popup.horizontal=on                                         \
                popup.align=center                                          \
                popup.background.image.scale=0.5                            \
            --add       item            spotify.back popup.spotify.name     \
            --set       spotify.back    icon=􀊎                              \
                                        icon.padding_left=5                 \
                                        icon.padding_right=5                \
                                        script="$PLUGIN_DIR/spotify.sh"     \
                                        label.drawing=off                   \
            --subscribe spotify.back    mouse.clicked                       \
                                                                            \
            --add       item            spotify.play popup.spotify.name     \
            --set       spotify.play    icon=􀊄                              \
                                        icon.padding_left=5                 \
                                        icon.padding_right=5                \
                                        updates=on                          \
                                        label.drawing=off                   \
                                        script="$PLUGIN_DIR/spotify.sh"     \
            --subscribe spotify.play    mouse.clicked spotify_change        \
                                                                            \
            --add       item            spotify.next popup.spotify.name     \
            --set       spotify.next    icon=􀊐                              \
                                        icon.padding_left=5                 \
                                        icon.padding_right=10               \
                                        label.drawing=off                   \
                                        script="$PLUGIN_DIR/spotify.sh"     \
            --subscribe spotify.next    mouse.clicked                       \
                                                                            \
            --add       item            spotify.shuffle popup.spotify.name  \
            --set       spotify.shuffle icon=􀊝                              \
                                        icon.highlight_color=0xff1DB954     \
                                        icon.padding_left=5                 \
                                        icon.padding_right=5                \
                                        label.drawing=off                   \
                                        script="$PLUGIN_DIR/spotify.sh"     \
            --subscribe spotify.shuffle mouse.clicked                       \
                                                                            \
            --add       bracket b_spotify                                   \
                                                spotify.name                \
                                                spotify.back                \
                                                spotify.play                \
                                                spotify.next                \
                                                spotify.shuffle             \
                                                spotify.repeat              \
            --set       b_spotify                                           \
                        label.color="$COLOR"                                \
                        background.drawing=on                               \
                        background.corner_radius="$CORNER_RADIUS"           \
                        background.padding_right=5                          \
                        background.border_color="$WHITE"                    \
                        background.color="$BAR_COLOR"                       \
                        background.padding_left=5