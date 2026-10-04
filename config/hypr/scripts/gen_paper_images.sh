#!/usr/bin/env bash

##################################
#     Made by Chief-Github       #
# https://github.com/Chief-Github#
##################################
if ps aux | grep "[m]pvpaper"
then 
    echo pmvpaper found;
    CURRENT_WALLPAPER=$(ps aux | grep "[m]pvpaper" | awk -F'(eDP-1|[*]) ' 'NF>1 {print $2; exit}')
    ffmpeg -ss 00:00:01 -i "$CURRENT_WALLPAPER" -frames:v 1 -q:v 2 -strict -2 /tmp/gen_wallpaper.jpg
    matugen image /tmp/gen_wallpaper.jpg && hyprctl keyword general:col.active_border $(cat ~/.config/hypr/matugen_colors.txt) 360deg
    rm /tmp/gen_wallpaper.jpg
    # ~/.config/cava/themes/dynamic_cava.conf
    setsid -f kitty +kitten panel \
        --edge=background --instance-group=cava-startup \
        --config ~/.config/kitty/cava_kitty.conf \
        --margin-top=238 --margin-right=1200 --margin-left=2 --margin-bottom=3 \
        --name=cava-startup cava -p ~/.config/cava/themes/dynamic_cava.conf >/dev/null 2>&1
else
    matugen image "$(awww query | grep -oP '(?<=image: ).*')" && hyprctl keyword general:col.active_border $(cat ~/.config/hypr/matugen_colors.txt) 360deg
fi

