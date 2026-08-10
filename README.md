# Pyr Dotfiles for BSPWM

Una configuración ligera y funcional para BSPWM sobre Debian/Parrot, usando:
- `bspwm`, `sxhkd`, `picom`, `polybar`, `feh`, `kitty`, `dunst`, `rofi`, `jgmenu`
- Tema único: `Pyr`
- Terminal predeterminado: `kitty`

## Instalación

Este proyecto incluye un instalador completo `install.sh` que copia la configuración, instala dependencias, instala fuentes locales y protege los archivos existentes con respaldos.

Ejecuta desde la raíz del repositorio:
```sh
bash ./install.sh
```

Opciones adicionales:
- `bash ./install.sh --skip-packages`  # omite instalación de paquetes apt
- `bash ./install.sh --download-fonts <URL>`  # descarga e instala fuentes desde un ZIP remoto
- `bash ./install.sh --download-wallpapers <URL>`  # descarga y extrae fondos adicionales en la carpeta del tema

Si prefieres instalar dependencias manualmente:
```sh
sudo apt update
sudo apt install bspwm sxhkd picom polybar feh kitty dunst rofi jgmenu \
  xsettingsd x11-xserver-utils x11-utils x11-xkb-utils xdotool xclip \
  libnotify-bin lxpolkit lightdm \
  mpd mpc ncmpcpp pamixer pavucontrol playerctl ffmpeg \
  brightnessctl network-manager bluez rfkill iputils-ping \
  flameshot maim imagemagick i3lock \
  zsh neovim geany bat eza jq bc pass gnupg \
  python3 python3-gi gir1.2-gtk-3.0 gir1.2-nm-1.0 python3-neovim \
  git curl nodejs npm ripgrep fd-find unzip ca-certificates \
  fonts-cascadia-code fonts-jetbrains-mono fonts-noto-color-emoji fontconfig \
  arc-theme papirus-icon-theme
```

Opcionales (el escritorio funciona sin ellos, con funciones degradadas):
```sh
sudo apt install qogir-icon-theme clipcat yazi simple-mtpfs mpv \
  zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search fzf python3-pip
```

El instalador copia la configuración de `config/bspwm`, `config/clipcat`, `config/geany`, `config/gtk-3.0`, `config/kitty`, `config/mpd`, `config/ncmpcpp`, `config/nvim`, `config/systemd`, `config/yazi` y `config/zsh`, además de `home/.zshrc`, `home/.gtkrc-2.0` y el contenido de `misc/` (scripts a `~/.local/bin`, ascii art a `~/.local/share/asciiart` y los lanzadores a `~/.local/share/applications`).

El script también descargará automáticamente los Nerd Fonts necesarios cuando falten: `CascadiaCode Nerd Font`, `JetBrainsMono Nerd Font` y `UbuntuMono Nerd Font`.

Si usas `zsh`, el script actualizará `~/.zshrc` y mantendrá respaldos de cualquier configuración previa en `~/.config/dotfiles-backup-*`.

Asegura que tu gestor de sesión use BSPWM y, una vez instalado, inicia sesión en BSPWM.

## Uso

- El único tema disponible es `Pyr`.
- Para aplicar o recargar el tema manualmente:
```sh
~/.config/bspwm/bin/Theme.sh
```
- Abre terminal con `Super + Return`.
- El selector de terminal actual usa `kitty`.
- El tema activo es `Pyr` y se aplica con `~/.config/bspwm/bin/Theme.sh`.
- La configuración de `nvim` está en `~/.config/nvim` y usa `lazy.nvim` para instalar plugins automáticamente en el primer arranque.
- El shell `zsh` se carga desde `~/.zshrc`; si usas `zsh` por defecto, verás la configuración de completado y prompt incluida.

## Actualizaciones

El contador de actualizaciones de la barra lo alimenta
`~/.config/bspwm/bin/Updates`, disparado por el timer de usuario `pyr-updates.timer`, que el
instalador habilita. El recuento refleja las listas de paquetes tal como estaban en el último
`apt update` (refrescarlas requiere root, así que el script nunca lo hace por su cuenta).

```sh
systemctl --user status pyr-updates.timer
Updates --print-updates
```

## Notas

- Ajusta los archivos en `~/.config/bspwm/rices/pyr` si deseas cambiar colores, fondos o comportamiento.
- Si no usas `LightDM`, configura tu gestor de inicio para lanzar `bspwm`.
- `ScreenLocker` usa las opciones de color de **i3lock-color**, que Debian no empaqueta. Con el
  `i3lock` estándar el bloqueo funciona pero sin el anillo ni los colores del tema.
- El fondo animado (`ENGINE="Animated"`) necesita `xwinwrap`, que tampoco está en Debian y hay que
  compilarlo a mano.
