# Pyr Dotfiles for BSPWM

Una configuración ligera y funcional para BSPWM sobre Debian/Parrot, usando:
- `bspwm`, `sxhkd`, `picom`, `polybar`, `feh`, `kitty`, `dunst`, `rofi`, `jgmenu`, `eww`
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

Si prefieres instalar dependencias manualmente, ejecuta:
```sh
sudo apt update
sudo apt install bspwm sxhkd picom polybar feh kitty dunst rofi jgmenu eww neovim zsh mpd ncmpcpp geany lightdm git curl python3 python3-neovim nodejs npm ripgrep fd-find unzip fonts-cascadia-code fonts-jetbrains-mono fonts-noto-color-emoji fontconfig arc-theme papirus-icon-theme qogir-icon-theme
```

Opcionalmente, para mejorar `zsh` y `nvim`:
```sh
sudo apt install zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search fzf python3-pip
```

El instalador también copia la configuración de `config/bspwm`, `config/kitty`, `config/nvim`, `config/zsh`, `config/eww`, `config/geany`, `config/mpd`, `config/ncmpcpp`, `config/gtk-3.0` y `config/yazi`.

El script también descargará automáticamente los Nerd Fonts necesarios cuando falten: `CascadiaCode Nerd Font`, `JetBrainsMono Nerd Font` y `UbuntuMono Nerd Font`.

Si usas `zsh`, el script actualizará `~/.zshrc` y mantendrá respaldos de cualquier configuración previa en `~/.config/dotfiles-backup-*`.

Asegura que tu gestor de sesión use BSPWM y, una vez instalado, inicia sesión en BSPWM.

## Uso

- El tema activo es `Pyr`.
- Para aplicar el tema manualmente:
```sh
~/.config/bspwm/bin/Theme.sh
```
- Abre terminal con `Super + Return`.
- El selector de terminal actual usa `kitty`.
- El archivo de tema actual es `~/.config/bspwm/.rice` y contiene `pyr`.
- La configuración de `nvim` está en `~/.config/nvim` y usa `lazy.nvim` para instalar plugins automáticamente en el primer arranque.
- El shell `zsh` se carga desde `~/.zshrc`; si usas `zsh` por defecto, verás la configuración de completado y prompt incluida.

## Notas

- Ajusta los archivos en `~/.config/bspwm/rices/pyr` si deseas cambiar colores, fondos o comportamiento.
- Si no usas `LightDM`, configura tu gestor de inicio para lanzar `bspwm`.
