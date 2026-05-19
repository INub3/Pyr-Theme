#!/bin/sh

# Set the gtk theme corresponding to rice
sed -i "$HOME"/.config/bspwm/config/xsettingsd \
    -e "s|Net/ThemeName .*|Net/ThemeName \"$gtk_theme\"|" \
    -e "s|Net/IconThemeName .*|Net/IconThemeName \"$gtk_icons\"|" \
    -e "s|Gtk/CursorThemeName .*|Gtk/CursorThemeName \"$gtk_cursor\"|"

mkdir -p "$HOME"/.icons/default
if [ ! -f "$HOME"/.icons/default/index.theme ]; then
    cat > "$HOME"/.icons/default/index.theme <<EOF
[Icon Theme]
Inherits=$gtk_cursor
EOF
else
    sed -i -e "s/Inherits=.*/Inherits=$gtk_cursor/" "$HOME"/.icons/default/index.theme
fi

# Reload daemon and apply gtk theme
if pidof -q xsettingsd; then
    pkill -1 xsettingsd
fi
xsetroot -cursor_name left_ptr
