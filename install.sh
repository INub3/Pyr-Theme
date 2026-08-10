#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
FONT_DIR="$HOME/.local/share/fonts"
CONFIG_DIR="$HOME/.config"
RICE_FILE="$CONFIG_DIR/bspwm/.rice"
THEME_NAME="pyr"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SHARE="$HOME/.local/share"
MISSING_PACKAGES=()

# Packages the desktop cannot start without.
CORE_PACKAGES=(
  # Window manager, compositor, bar and menus
  bspwm sxhkd picom polybar feh kitty dunst rofi jgmenu
  # X11 helpers used by bspwmrc, the theme modules and the bin/ scripts
  xsettingsd x11-xserver-utils x11-utils x11-xkb-utils xdotool xclip
  # Notifications, polkit agent and session
  libnotify-bin lxpolkit lightdm
  # Audio / media stack driving Volume, MediaControl and the mpd modules
  mpd mpc ncmpcpp pamixer pavucontrol playerctl ffmpeg
  # Hardware controls used by the polybar modules
  brightnessctl network-manager bluez rfkill iputils-ping
  # Screenshots, screen locking and wallpaper tooling
  flameshot maim imagemagick i3lock
  # Shell, editors and CLI tools referenced by .zshrc / Term / RofiPass
  zsh neovim geany bat eza jq bc pass gnupg
  # Runtime for the Python helpers (RiceEditor, NetManagerDM)
  python3 python3-gi gir1.2-gtk-3.0 gir1.2-nm-1.0 python3-neovim
  # Build/base tooling and fonts
  git curl nodejs npm ripgrep fd-find unzip ca-certificates
  fonts-cascadia-code fonts-jetbrains-mono fonts-noto-color-emoji fontconfig
  arc-theme papirus-icon-theme
)

# Nice to have: the desktop degrades gracefully when these are missing.
OPTIONAL_PACKAGES=(
  qogir-icon-theme clipcat yazi simple-mtpfs mpv
  zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search fzf python3-pip
)

apt_package_available() {
  apt-cache show "$1" >/dev/null 2>&1
}

# `dpkg -s` also succeeds for packages that were removed but not purged
# (Status: deinstall ok config-files), so check the status field itself.
pkg_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^install ok installed$'
}

# install_pkg_group <label> <name-of-array> [name-of-failed-array]
# Installs every package of the group, recording the ones apt could not provide.
install_pkg_group() {
  local label="$1"
  local -n _pkgs="$2"
  local track_failures="${3:-}"

  printf '\n[install] Installing %s packages...\n' "$label"
  local pkg
  for pkg in "${_pkgs[@]}"; do
    if pkg_installed "$pkg"; then
      printf '[install] %s already installed\n' "$pkg"
      continue
    fi
    if ! apt_package_available "$pkg"; then
      printf '[install] %s package not available in apt repos: %s\n' "$label" "$pkg"
      [ -n "$track_failures" ] && MISSING_PACKAGES+=("$pkg")
      continue
    fi
    if sudo apt-get install -y "$pkg"; then
      printf '[install] installed %s\n' "$pkg"
    else
      printf '[install] warning: could not install %s\n' "$pkg"
      [ -n "$track_failures" ] && MISSING_PACKAGES+=("$pkg")
    fi
  done
}

install_from_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "[install] ERROR: apt-get not found on this system. Skipping package installation."
    return 1
  fi

  sudo apt-get update

  install_pkg_group "core" CORE_PACKAGES track
  install_pkg_group "optional" OPTIONAL_PACKAGES

  if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    printf '\n[install] WARNING: some core packages could not be installed:\n'
    printf '  %s\n' "${MISSING_PACKAGES[@]}"
    printf '[install] Please install missing packages manually and rerun the script.\n'
  fi
}

backup_path() {
  local target="$1"
  if [ -e "$target" ]; then
    mkdir -p "$BACKUP_ROOT"
    mv "$target" "$BACKUP_ROOT/"
    printf '[install] backed up %s -> %s\n' "$target" "$BACKUP_ROOT"
  fi
}

copy_path() {
  local source="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -d "$source" ]; then
    rm -rf "$dest"
    cp -r "$source" "$dest"
  else
    cp "$source" "$dest"
  fi
  printf '[install] copied %s -> %s\n' "$source" "$dest"
}

install_fonts() {
  mkdir -p "$FONT_DIR"
  local fonts_source="$REPO_ROOT/misc/fonts"
  if [ -d "$fonts_source" ]; then
    find "$fonts_source" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' \) -print0 |
      xargs -0 -I{} cp -n '{}' "$FONT_DIR/" || true
    printf '[install] copied local fonts to %s\n' "$FONT_DIR"
  fi
  ensure_nerd_fonts
  fc-cache -f "$FONT_DIR" || true
  printf '[install] refreshed font cache\n'
}

is_font_installed() {
  local font_name="$1"
  fc-list | grep -iq -- "$font_name"
}

install_nerd_font() {
  local family="$1"
  local download_name="$2"
  if is_font_installed "$family Nerd Font"; then
    printf '[install] %s Nerd Font already available\n' "$family"
    return 0
  fi

  local tmp_zip="$HOME/.cache/pyr-install-fonts/${download_name}.zip"
  local tmp_dir="$HOME/.cache/pyr-install-fonts/${download_name}"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${download_name}.zip"

  mkdir -p "$tmp_dir"
  printf '[install] downloading %s Nerd Font from %s\n' "$family" "$url"
  if ! curl -fL -o "$tmp_zip" "$url"; then
    printf '[install] warning: failed to download %s Nerd Font from %s\n' "$family" "$url"
    rm -rf "$tmp_dir" "$tmp_zip"
    return 1
  fi

  unzip -o "$tmp_zip" -d "$tmp_dir"
  find "$tmp_dir" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -exec cp -n '{}' "$FONT_DIR/" \;
  rm -rf "$tmp_dir" "$tmp_zip"
  printf '[install] installed %s Nerd Font to %s\n' "$family" "$FONT_DIR"
}

ensure_nerd_fonts() {
  install_nerd_font "CascadiaCode" "CascadiaCode" || true
  install_nerd_font "JetBrainsMono" "JetBrainsMono" || true
  install_nerd_font "UbuntuMono" "UbuntuMono" || true
}

download_fonts() {
  local url="$1"
  local tmp_file="$HOME/.cache/pyr-install-fonts.zip"
  mkdir -p "$(dirname "$tmp_file")"
  printf '[install] downloading fonts from %s\n' "$url"
  curl -L -o "$tmp_file" "$url"
  unzip -o "$tmp_file" -d "$HOME/.cache/pyr-install-fonts"
  find "$HOME/.cache/pyr-install-fonts" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print0 |
    xargs -0 -I{} cp -n '{}' "$FONT_DIR/"
  rm -rf "$HOME/.cache/pyr-install-fonts" "$tmp_file"
  fc-cache -f "$FONT_DIR" || true
  printf '[install] downloaded and installed fonts from URL\n'
}

download_wallpapers() {
  local url="$1"
  local tmp_file="$HOME/.cache/pyr-install-wallpapers.zip"
  mkdir -p "$(dirname "$tmp_file")"
  printf '[install] downloading wallpapers from %s\n' "$url"
  curl -L -o "$tmp_file" "$url"
  mkdir -p "$REPO_ROOT/config/bspwm/rices/$THEME_NAME/walls"
  unzip -o "$tmp_file" -d "$REPO_ROOT/config/bspwm/rices/$THEME_NAME/walls"
  rm -f "$tmp_file"
  printf '[install] downloaded additional wallpapers into %s\n' "$REPO_ROOT/config/bspwm/rices/$THEME_NAME/walls"
}

install_configs() {
  local items=(
    "config/bspwm"
    "config/clipcat"
    "config/geany"
    "config/gtk-3.0"
    "config/kitty"
    "config/mpd"
    "config/ncmpcpp"
    "config/nvim"
    "config/systemd"
    "config/yazi"
    "config/zsh"
  )

  for item in "${items[@]}"; do
    local src="$REPO_ROOT/$item"
    local dest="$CONFIG_DIR/$(basename "$item")"
    if [ -e "$src" ]; then
      backup_path "$dest"
      copy_path "$src" "$dest"
    fi
  done

  # zcompdump and zhistory are per-machine state, so they are not shipped;
  # zsh recreates them on first login as long as the directory exists.
  mkdir -p "$CONFIG_DIR/zsh"

  backup_path "$HOME/.zshrc"
  copy_path "$REPO_ROOT/home/.zshrc" "$HOME/.zshrc"

  # GTK2 apps read ~/.gtkrc-2.0; without it they ignore the theme entirely.
  if [ -f "$REPO_ROOT/home/.gtkrc-2.0" ]; then
    backup_path "$HOME/.gtkrc-2.0"
    copy_path "$REPO_ROOT/home/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
  fi
}

# WallSelect, WallSync and ScreenLocker call `magick`, the ImageMagick 7 entry
# point. Debian 12 still ships ImageMagick 6, where the equivalent is `convert`.
# The invocations used here are compatible, so bridge them with a small wrapper.
ensure_magick_shim() {
  if command -v magick >/dev/null 2>&1; then
    return 0
  fi
  if ! command -v convert >/dev/null 2>&1; then
    printf '[install] warning: neither magick nor convert found; wallpaper previews and the lockscreen blur will not work\n'
    return 1
  fi

  mkdir -p "$LOCAL_BIN"
  cat > "$LOCAL_BIN/magick" <<'EOF'
#!/bin/sh
# Compatibility shim: ImageMagick 6 (Debian 12) has no `magick` entry point.
exec convert "$@"
EOF
  chmod +x "$LOCAL_BIN/magick"
  printf '[install] ImageMagick 6 detected; installed a magick -> convert shim in %s\n' "$LOCAL_BIN"
}

# misc/ holds pieces the desktop actually calls at runtime:
#   misc/bin/sysfetch     <- Term --fetch
#   misc/bin/colorscript  <- .zshrc greeting, reads ~/.local/share/asciiart
#   misc/applications/*   <- desktop entries for RiceEditor and the fetch popup
install_misc() {
  mkdir -p "$LOCAL_BIN" "$LOCAL_SHARE/applications"

  if [ -d "$REPO_ROOT/misc/bin" ]; then
    find "$REPO_ROOT/misc/bin" -maxdepth 1 -type f -exec cp '{}' "$LOCAL_BIN/" \;
    find "$LOCAL_BIN" -maxdepth 1 -type f -exec chmod +x '{}' \; || true
    printf '[install] installed helper scripts into %s\n' "$LOCAL_BIN"
  fi

  if [ -d "$REPO_ROOT/misc/asciiart" ]; then
    backup_path "$LOCAL_SHARE/asciiart"
    copy_path "$REPO_ROOT/misc/asciiart" "$LOCAL_SHARE/asciiart"
  fi

  ensure_magick_shim

  if [ -d "$REPO_ROOT/misc/applications" ]; then
    find "$REPO_ROOT/misc/applications" -maxdepth 1 -type f \
      -exec cp '{}' "$LOCAL_SHARE/applications/" \;
    printf '[install] installed desktop entries into %s\n' "$LOCAL_SHARE/applications"
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$LOCAL_SHARE/applications" >/dev/null 2>&1 || true
    fi
  fi
}

ensure_bin_executables() {
  local bin_dir="$CONFIG_DIR/bspwm/bin"
  if [ -d "$bin_dir" ]; then
    find "$bin_dir" -maxdepth 1 -type f -exec chmod +x '{}' \; || true
    printf '[install] ensured executables in: %s\n' "$bin_dir"
  fi
}

# Without the timer the updates counter in polybar / the profilecard never
# gets a value written to ~/.cache/Updates.txt.
enable_user_units() {
  if ! command -v systemctl >/dev/null 2>&1; then
    printf '[install] systemctl not available, skipping user timer setup\n'
    return 0
  fi

  systemctl --user daemon-reload >/dev/null 2>&1 || true
  if systemctl --user enable --now pyr-updates.timer >/dev/null 2>&1; then
    printf '[install] enabled pyr-updates.timer\n'
  else
    printf '[install] warning: could not enable pyr-updates.timer\n'
    printf '[install] enable it later with: systemctl --user enable --now pyr-updates.timer\n'
  fi

  # Populate the counter once so the module is not empty until the first tick.
  "$CONFIG_DIR/bspwm/bin/Updates" --sync-polybar >/dev/null 2>&1 || true
}

write_rice_file() {
  mkdir -p "$CONFIG_DIR/bspwm"
  printf '%s\n' "$THEME_NAME" > "$RICE_FILE"
  printf '[install] wrote theme name %s into %s\n' "$THEME_NAME" "$RICE_FILE"
}

set_shell() {
  if [ "$(basename "$SHELL")" != "zsh" ]; then
    if command -v zsh >/dev/null 2>&1; then
      chsh -s "$(command -v zsh)" || true
      printf '[install] configured zsh as login shell (may require logout/login).\n'
    else
      printf '[install] warning: zsh not available to set as shell.\n'
    fi
  fi
}

apply_theme() {
  if [ -z "${DISPLAY:-}" ]; then
    printf '[install] skipping theme application because no X display is available\n'
    return 0
  fi

  if [ ! -x "$CONFIG_DIR/bspwm/bin/Theme.sh" ]; then
    printf '[install] warning: Theme.sh not found or not executable at %s\n' "$CONFIG_DIR/bspwm/bin/Theme.sh"
    return 1
  fi

  if ! command -v bspc >/dev/null 2>&1 || ! pgrep -x bspwm >/dev/null 2>&1; then
    printf '[install] warning: BSPWM does not appear to be running; skipping theme application.\n'
    printf '[install] You can apply the theme later with: ~/.config/bspwm/bin/Theme.sh\n'
    return 1
  fi

  "$CONFIG_DIR/bspwm/bin/Theme.sh"
  printf '[install] applied theme using Theme.sh\n'
}

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --skip-packages          Skip apt package installation.
  --download-fonts URL     Download and install fonts from a ZIP URL.
  --download-wallpapers URL  Download extra wallpapers from a ZIP URL into the Pyr walls folder.
  --help                   Show this help message.
EOF
}

require_arg() {
  if [ "$#" -lt 2 ] || [ -z "$2" ]; then
    printf '[install] ERROR: %s requires an argument\n' "$1"
    usage
    exit 1
  fi
}

main() {
  local install_packages=true
  local download_fonts_url=""
  local download_wallpapers_url=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --skip-packages)
        install_packages=false
        shift
        ;;
      --download-fonts)
        require_arg "$1" "${2:-}"
        download_fonts_url="$2"
        shift 2
        ;;
      --download-wallpapers)
        require_arg "$1" "${2:-}"
        download_wallpapers_url="$2"
        shift 2
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        printf '[install] ERROR: invalid option %s\n' "$1"
        usage
        exit 1
        ;;
    esac
  done

  printf '[install] Running install.sh from %s\n' "$REPO_ROOT"

  if [ "$install_packages" = true ]; then
    install_from_apt || true
  fi

  install_configs
  install_misc
  ensure_bin_executables
  install_fonts

  if [ -n "$download_fonts_url" ]; then
    download_fonts "$download_fonts_url"
  fi

  if [ -n "$download_wallpapers_url" ]; then
    download_wallpapers "$download_wallpapers_url"
  fi

  write_rice_file
  enable_user_units
  set_shell
  apply_theme

  printf '\n[install] Installation complete. If zsh is your default shell, open a new terminal or login again.\n'
  printf '[install] Existing files were backed up to %s if they existed.\n' "$BACKUP_ROOT"
}

main "$@"
