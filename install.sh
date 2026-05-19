#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
FONT_DIR="$HOME/.local/share/fonts"
CONFIG_DIR="$HOME/.config"
RICE_FILE="$CONFIG_DIR/bspwm/.rice"
THEME_NAME="pyr"

CORE_PACKAGES=(
  bspwm sxhkd picom polybar feh kitty dunst rofi jgmenu neovim zsh mpd ncmpcpp geany lightdm git curl python3 python3-neovim nodejs npm ripgrep fd-find unzip ca-certificates fonts-cascadia-code fonts-jetbrains-mono fonts-noto-color-emoji fontconfig arc-theme papirus-icon-theme
)
OPTIONAL_PACKAGES=(
  eww qogir-icon-theme zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search fzf python3-pip clipcat
)

apt_package_available() {
  apt-cache show "$1" >/dev/null 2>&1
}

install_from_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "[install] ERROR: apt-get not found on this system. Skipping package installation."
    return 1
  fi

  sudo apt-get update
  local failed=()

  for pkg in "${CORE_PACKAGES[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      printf '[install] %s already installed\n' "$pkg"
      continue
    fi
    if ! apt_package_available "$pkg"; then
      printf '[install] warning: core package not available in apt repos: %s\n' "$pkg"
      failed+=("$pkg")
      continue
    fi
    if sudo apt-get install -y "$pkg" >/dev/null 2>&1; then
      printf '[install] installed %s\n' "$pkg"
    else
      printf '[install] warning: could not install %s\n' "$pkg"
      failed+=("$pkg")
    fi
  done

  if [ ${#OPTIONAL_PACKAGES[@]} -gt 0 ]; then
    printf '\n[install] Installing optional packages...\n'
    for pkg in "${OPTIONAL_PACKAGES[@]}"; do
      if dpkg -s "$pkg" >/dev/null 2>&1; then
        printf '[install] %s already installed\n' "$pkg"
        continue
      fi
      if ! apt_package_available "$pkg"; then
        printf '[install] optional package unavailable: %s\n' "$pkg"
        continue
      fi
      if sudo apt-get install -y "$pkg" >/dev/null 2>&1; then
        printf '[install] installed optional %s\n' "$pkg"
      else
        printf '[install] optional package unavailable: %s\n' "$pkg"
      fi
    done
  fi

  if [ ${#failed[@]} -gt 0 ]; then
    printf '\n[install] WARNING: some core packages could not be installed:\n'
    printf '  %s\n' "${failed[@]}"
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
  fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
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
  if ! curl -fL -o "$tmp_zip" "$url" >/dev/null 2>&1; then
    printf '[install] warning: failed to download %s Nerd Font from %s\n' "$family" "$url"
    rm -rf "$tmp_dir" "$tmp_zip"
    return 1
  fi

  unzip -o "$tmp_zip" -d "$tmp_dir" >/dev/null 2>&1
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
  unzip -o "$tmp_file" -d "$HOME/.cache/pyr-install-fonts" >/dev/null 2>&1
  find "$HOME/.cache/pyr-install-fonts" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print0 |
    xargs -0 -I{} cp -n '{}' "$FONT_DIR/"
  rm -rf "$HOME/.cache/pyr-install-fonts" "$tmp_file"
  fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
  printf '[install] downloaded and installed fonts from URL\n'
}

download_wallpapers() {
  local url="$1"
  local tmp_file="$HOME/.cache/pyr-install-wallpapers.zip"
  mkdir -p "$(dirname "$tmp_file")"
  printf '[install] downloading wallpapers from %s\n' "$url"
  curl -L -o "$tmp_file" "$url"
  mkdir -p "$REPO_ROOT/config/bspwm/rices/$THEME_NAME/walls"
  unzip -o "$tmp_file" -d "$REPO_ROOT/config/bspwm/rices/$THEME_NAME/walls" >/dev/null 2>&1
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
    "config/paru"
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

  backup_path "$HOME/.zshrc"
  copy_path "$REPO_ROOT/home/.zshrc" "$HOME/.zshrc"
}

install_eww_via_cargo() {
  if command -v eww >/dev/null 2>&1; then
    return 0
  fi

  if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
    printf '[install] cargo/rust not available, skipping eww source install\n'
    return 1
  fi

  local tmp_dir="$HOME/.cache/pyr-install-eww"
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"

  printf '[install] cloning eww repository for cargo install\n'
  if ! git clone --depth 1 https://github.com/elkowar/eww.git "$tmp_dir" >/dev/null 2>&1; then
    printf '[install] warning: failed to clone eww repository\n'
    return 1
  fi

  printf '[install] building eww from source via cargo\n'
  if (cd "$tmp_dir" && cargo install --path . --locked --no-default-features --features x11 >/dev/null 2>&1); then
    printf '[install] installed eww via cargo\n'
    return 0
  fi

  printf '[install] warning: cargo build of eww failed\n'
  return 1
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
    printf '[install] warning: BSPWM does not appear to be running; skipping theme application\n'
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
        download_fonts_url="$2"
        shift 2
        ;;
      --download-wallpapers)
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
  install_fonts

  if ! command -v eww >/dev/null 2>&1; then
    install_eww_via_cargo || printf '[install] warning: eww is not installed. To install manually, install rust/rustup and build from https://github.com/elkowar/eww\n'
  fi

  if [ -n "$download_fonts_url" ]; then
    download_fonts "$download_fonts_url"
  fi

  if [ -n "$download_wallpapers_url" ]; then
    download_wallpapers "$download_wallpapers_url"
  fi

  write_rice_file
  set_shell
  apply_theme

  printf '\n[install] Installation complete. If zsh is your default shell, open a new terminal or login again.\n'
  printf '[install] Existing files were backed up to %s if they existed.\n' "$BACKUP_ROOT"
}

main "$@"
