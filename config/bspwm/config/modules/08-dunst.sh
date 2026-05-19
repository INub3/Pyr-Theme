#!/bin/sh

dunst_config_file="$HOME/.config/bspwm/config/dunstrc"

sed -i "$dunst_config_file" \
    -e "s/origin = .*/origin = ${dunst_origin}/" \
    -e "s/offset = .*/offset = ${dunst_offset}/" \
    -e "s/transparency = .*/transparency = ${dunst_transparency}/" \
    -e "s/^corner_radius = .*/corner_radius = ${dunst_corner_radius}/" \
    -e "s/frame_width = .*/frame_width = ${dunst_border}/" \
    -e "s/frame_color = .*/frame_color = \"${dunst_frame_color}\"/" \
    -e "s/font = .*/font = ${dunst_font}/" \
    -e "s/foreground='.*'/foreground='${blue}'/" \
    -e "s/icon_theme = .*/icon_theme = \"${dunst_icon_theme}, Adwaita\"/"

sed -i '/urgency_low/Q' "$dunst_config_file"
cat >>"$dunst_config_file" <<-_EOF_
[urgency_low]
timeout = 3
background = "${bg}"
foreground = "${green}"

[urgency_normal]
timeout = 5
background = "${bg}"
foreground = "${fg}"

[urgency_critical]
timeout = 0
background = "${bg}"
foreground = "${red}"
_EOF_

if command -v dunstctl >/dev/null 2>&1; then
    dunstctl reload >/dev/null 2>&1 || pkill -USR1 dunst >/dev/null 2>&1 || true
elif pidof -q dunst; then
    pkill -USR1 dunst >/dev/null 2>&1 || true
fi
