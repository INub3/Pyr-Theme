#!/bin/sh
# GTK settings live in three places, each read by a different audience:
#
#   xsettingsd   -> GTK3 apps, live (the daemon overrides settings.ini while
#                   it runs, so this is what actually wins in a bspwm session)
#   settings.ini -> GTK3 apps started without an XSETTINGS manager
#   .gtkrc-2.0   -> GTK2 apps, which ignore both of the above
#
# All three are kept in sync here so changing a gtk_* variable in
# theme-config.bash is enough. Keys absent from a file are simply not matched,
# so the shipped files must already contain every key patched below.

xsettings_file="$HOME/.config/bspwm/config/xsettingsd"
gtk3_ini="$HOME/.config/gtk-3.0/settings.ini"
gtk2_rc="$HOME/.gtkrc-2.0"

# --- GTK3, live -------------------------------------------------------------
if [ -f "$xsettings_file" ]; then
    sed -i "$xsettings_file" \
        -e "s|Net/ThemeName .*|Net/ThemeName \"$gtk_theme\"|" \
        -e "s|Net/IconThemeName .*|Net/IconThemeName \"$gtk_icons\"|" \
        -e "s|Gtk/CursorThemeName .*|Gtk/CursorThemeName \"$gtk_cursor\"|" \
        -e "s|Gtk/FontName .*|Gtk/FontName \"$gtk_font\"|" \
        -e "s|Xft/HintStyle .*|Xft/HintStyle \"$gtk_hintstyle\"|" \
        -e "s|Xft/RGBA .*|Xft/RGBA \"$gtk_rgba\"|"
fi

# --- GTK3, fallback ---------------------------------------------------------
# gtk-application-prefer-dark-theme has no XSETTINGS equivalent, so this file
# is the only way to request the dark variant of a theme that ships both.
if [ -f "$gtk3_ini" ]; then
    sed -i "$gtk3_ini" \
        -e "s|^gtk-theme-name=.*|gtk-theme-name=$gtk_theme|" \
        -e "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=$gtk_icons|" \
        -e "s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=$gtk_cursor|" \
        -e "s|^gtk-font-name=.*|gtk-font-name=$gtk_font|" \
        -e "s|^gtk-application-prefer-dark-theme=.*|gtk-application-prefer-dark-theme=$gtk_prefer_dark|" \
        -e "s|^gtk-xft-hintstyle=.*|gtk-xft-hintstyle=$gtk_hintstyle|" \
        -e "s|^gtk-xft-rgba=.*|gtk-xft-rgba=$gtk_rgba|"
fi

# --- GTK2 -------------------------------------------------------------------
# GTK2 has no prefer-dark setting; a dark GTK2 look needs a dark theme name.
if [ -f "$gtk2_rc" ]; then
    sed -i "$gtk2_rc" \
        -e "s|^gtk-theme-name=.*|gtk-theme-name=\"$gtk_theme\"|" \
        -e "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=\"$gtk_icons\"|" \
        -e "s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=\"$gtk_cursor\"|" \
        -e "s|^gtk-font-name=.*|gtk-font-name=\"$gtk_font\"|" \
        -e "s|^gtk-xft-hintstyle=.*|gtk-xft-hintstyle=\"$gtk_hintstyle\"|" \
        -e "s|^gtk-xft-rgba=.*|gtk-xft-rgba=\"$gtk_rgba\"|"
fi

# --- Cursor -----------------------------------------------------------------
mkdir -p "$HOME"/.icons/default
if [ ! -f "$HOME"/.icons/default/index.theme ]; then
    cat > "$HOME"/.icons/default/index.theme <<EOF
[Icon Theme]
Inherits=$gtk_cursor
EOF
else
    sed -i -e "s/Inherits=.*/Inherits=$gtk_cursor/" "$HOME"/.icons/default/index.theme
fi

# Warn instead of silently falling back to Adwaita when the theme is missing.
theme_found=0
for dir in "$HOME/.themes" "$HOME/.local/share/themes" /usr/share/themes; do
    [ -d "$dir/$gtk_theme" ] && theme_found=1 && break
done
if [ "$theme_found" -eq 0 ]; then
    printf '[theme] warning: GTK theme "%s" not found; GTK apps will use Adwaita\n' "$gtk_theme" >&2
fi

# Reload daemon and apply gtk theme
if pidof -q xsettingsd; then
    pkill -1 xsettingsd
fi
xsetroot -cursor_name left_ptr
