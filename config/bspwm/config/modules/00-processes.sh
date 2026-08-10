#!/bin/sh

# Function to wait for processes to finish correctly
wait_for_termination() {
    process_name="$1"
    while pgrep -f "$process_name" >/dev/null; do
        sleep 0.2
    done
}

# Kill the bar before reloading the theme
if pgrep -x polybar >/dev/null; then
    polybar-msg cmd quit >/dev/null 2>&1
    wait_for_termination "polybar"
fi

# 07-bar.sh starts a fresh bspc-listener on every theme reload, so drop the
# previous one first instead of stacking duplicates.
if pgrep -f "bspwm/bin/bspc-listener" >/dev/null; then
    pkill -f "bspwm/bin/bspc-listener"
    wait_for_termination "bspwm/bin/bspc-listener"
fi

# Kill animated wallpaper if is active
if pgrep -x xwinwrap >/dev/null; then
    pkill xwinwrap
    wait_for_termination "xwinwrap"
fi

if [ -f /tmp/wall_refresh.pid ]; then
    kill $(cat /tmp/wall_refresh.pid) 2>/dev/null
    rm -f /tmp/wall_refresh.pid
fi
