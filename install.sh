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
  # xxhash provides xxh64sum, which WallSelect uses to validate its preview cache
  flameshot maim imagemagick i3lock xxhash
  # Shell, editors and CLI tools referenced by .zshrc / Term / RofiPass
  zsh neovim geany bat eza jq bc pass gnupg
  # GUI apps bound to keys in sxhkdrc (thunar = super + f)
  thunar
  # Runtime for the Python helpers (RiceEditor, NetManagerDM)
  python3 python3-gi gir1.2-gtk-3.0 gir1.2-nm-1.0 python3-neovim
  # Build/base tooling and fonts
  git curl nodejs npm ripgrep fd-find unzip ca-certificates
  fonts-cascadia-code fonts-jetbrains-mono fonts-noto-color-emoji fontconfig
  arc-theme papirus-icon-theme
)

# Nice to have: the desktop degrades gracefully when these are missing.
# yazi and clipcat are NOT here: Debian does not package them, so they get their
# own installers further down (see install_extras).
# A browser is personal, so firefox-esr is only a fallback: OpenApps --browser
# picks up firefox, firefox-esr, chromium or brave, whichever is present.
OPTIONAL_PACKAGES=(
  qogir-icon-theme simple-mtpfs mpv firefox-esr
  zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search fzf python3-pip
)

# Upstream sources for the two tools Debian does not ship.
YAZI_KEYRING_URL="https://yazi-rs.github.io/builds/yazi-keyring.gpg"
YAZI_REPO_URL="https://yazi-rs.github.io/builds/"
YAZI_SUITE="stable"
CLIPCAT_REPO="xrelkd/clipcat"

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

# ---------------------------------------------------------------------------
# Tools Debian does not package. Both pull from upstream, so they are grouped
# behind --skip-extras for anyone who would rather not add third-party sources.
# ---------------------------------------------------------------------------

# Yazi ships its own APT repository (suites: stable, nightly; amd64 + arm64).
install_yazi() {
  if command -v yazi >/dev/null 2>&1; then
    printf '[install] yazi already available: %s\n' "$(command -v yazi)"
    return 0
  fi

  local arch
  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64|arm64) ;;
    *)
      printf '[install] warning: the yazi repository has no %s build, skipping\n' "$arch"
      return 1
      ;;
  esac

  local keyring="/usr/share/keyrings/yazi-keyring.gpg"
  local tmp_key="$HOME/.cache/yazi-keyring.gpg"
  mkdir -p "$(dirname "$tmp_key")"

  # Download to a temp file first: `curl | sudo tee` would happily install an
  # HTML error page as if it were a signing key.
  printf '[install] fetching the yazi signing key\n'
  if ! curl -fsSL -o "$tmp_key" "$YAZI_KEYRING_URL" || [ ! -s "$tmp_key" ]; then
    printf '[install] warning: could not download the yazi signing key from %s\n' "$YAZI_KEYRING_URL"
    rm -f "$tmp_key"
    return 1
  fi

  sudo install -m 0644 "$tmp_key" "$keyring"
  rm -f "$tmp_key"

  printf 'deb [arch=%s signed-by=%s] %s %s main\n' \
    "$arch" "$keyring" "$YAZI_REPO_URL" "$YAZI_SUITE" |
    sudo tee /etc/apt/sources.list.d/yazi.list >/dev/null
  printf '[install] added the yazi repository (%s, %s)\n' "$YAZI_SUITE" "$arch"

  sudo apt-get update
  if sudo apt-get install -y yazi; then
    printf '[install] installed yazi\n'
    return 0
  fi

  printf '[install] warning: could not install yazi from its repository\n'
  return 1
}

# Clipcat publishes .deb assets on its GitHub releases (amd64 + arm64).
install_clipcat() {
  if command -v clipcatd >/dev/null 2>&1; then
    printf '[install] clipcat already available: %s\n' "$(command -v clipcatd)"
    return 0
  fi

  local arch
  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64|arm64) ;;
    *)
      printf '[install] warning: clipcat publishes no %s package, skipping\n' "$arch"
      return 1
      ;;
  esac

  # Resolve the newest tag by following the /releases/latest redirect, which
  # avoids the GitHub API rate limit.
  local version
  version="$(curl -fsSL -o /dev/null -w '%{url_effective}' \
    "https://github.com/${CLIPCAT_REPO}/releases/latest" 2>/dev/null)" || true
  version="${version##*/}"

  case "$version" in
    v[0-9]*) ;;
    *)
      printf '[install] warning: could not resolve the latest clipcat release (got "%s")\n' "$version"
      return 1
      ;;
  esac

  local deb="clipcat_${version#v}_${arch}.deb"
  local url="https://github.com/${CLIPCAT_REPO}/releases/download/${version}/${deb}"
  local tmp_deb="$HOME/.cache/${deb}"
  mkdir -p "$(dirname "$tmp_deb")"

  printf '[install] downloading clipcat %s (%s)\n' "$version" "$arch"
  if ! curl -fsSL -o "$tmp_deb" "$url" || [ ! -s "$tmp_deb" ]; then
    printf '[install] warning: could not download %s\n' "$url"
    rm -f "$tmp_deb"
    return 1
  fi

  # `apt-get install ./pkg.deb` resolves dependencies; plain `dpkg -i` leaves
  # the package half-configured when any are missing.
  if sudo apt-get install -y "$tmp_deb"; then
    printf '[install] installed clipcat %s\n' "$version"
  elif sudo dpkg -i "$tmp_deb" && sudo apt-get -f install -y; then
    printf '[install] installed clipcat %s (with dependency repair)\n' "$version"
  else
    printf '[install] warning: could not install %s\n' "$deb"
    rm -f "$tmp_deb"
    return 1
  fi

  rm -f "$tmp_deb"
  return 0
}

install_extras() {
  if ! command -v apt-get >/dev/null 2>&1; then
    printf '[install] apt-get not available, skipping yazi/clipcat\n'
    return 1
  fi
  install_yazi || true
  install_clipcat || true
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
  --skip-extras            Do not install yazi/clipcat from upstream sources.
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
  local want_extras=true
  local download_fonts_url=""
  local download_wallpapers_url=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --skip-packages)
        install_packages=false
        shift
        ;;
      --skip-extras)
        want_extras=false
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

  if [ "$want_extras" = true ]; then
    install_extras || true
  else
    printf '[install] skipping yazi/clipcat (--skip-extras)\n'
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
