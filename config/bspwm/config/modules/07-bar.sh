#!/bin/sh

. "$HOME"/.config/bspwm/rices/"$RICE"/Bar.bash

# Start a lightweight bspc event listener to keep polybar/eww in sync
if [ -x "$HOME"/.config/bspwm/bin/bspc-listener ]; then
	"$HOME"/.config/bspwm/bin/bspc-listener &
fi
