# Guía de Instalación Manual del Tema Pyr para BSPWM

Esta guía proporciona un proceso manual paso a paso para instalar y configurar el tema **Pyr** en un sistema basado en BSPWM, sin depender de scripts automatizados. Está diseñada para entornos como LFS/BLFS, donde la instalación se realiza desde fuentes y de manera personalizada. El tema Pyr es un setup minimalista y funcional, centrado en BSPWM con kitty como terminal, usando colores Tokyo Night y fuentes Nerd Fonts.

## Prerrequisitos

Antes de comenzar, asegúrate de tener un sistema con BSPWM funcionando. Instala manualmente los siguientes componentes desde fuentes (en LFS/BLFS, compila desde el código fuente disponible en sus repositorios oficiales):

- **BSPWM**: Window manager principal.
- **SXHKD**: Hotkey daemon para BSPWM.
- **Picom**: Compositor para efectos (transparencias, sombras).
- **Polybar**: Barra de estado.
- **Feh**: Visor de imágenes para wallpapers.
- **Kitty**: Terminal emulator (predeterminado en este setup).
- **Dunst**: Notificador de escritorio.
- **Rofi**: Lanzador de aplicaciones y menús.
- **Jgmenu**: Menú alternativo.
- **EWW**: Widgets para la barra (opcional, pero recomendado).
- **Neovim**: Editor de texto.
- **Zsh**: Shell alternativo.
- **MPD y Ncmpcpp**: Para música.
- **Geany**: Editor ligero.
- **Yazi**: Explorador de archivos.
- **Clipcat**: Gestor de clipboard (opcional).
- **Paru**: AUR helper (solo si usas Arch-like, opcional para LFS).
- **Systemd**: Para servicios de usuario (opcional).

Además, instala bibliotecas necesarias como GTK, Xorg, etc., según tu sistema LFS/BLFS.

## Paso 1: Instalación de Dependencias

Instala los paquetes requeridos compilando desde fuentes. Para LFS/BLFS, sigue las instrucciones en los libros oficiales o BLFS para cada paquete. Asegúrate de que estén en tu PATH y configurados correctamente.

Ejemplos de comandos de compilación (adaptados a tu entorno):

```bash
# Ejemplo genérico para un paquete (reemplaza con el real)
cd /sources
tar -xvf package.tar.gz
cd package
./configure --prefix=/usr
make
make install
```

Instala al menos:
- bspwm, sxhkd, picom, polybar, feh, kitty, dunst, rofi, jgmenu, eww, neovim, zsh, mpd, ncmpcpp, geany, yazi, clipcat (si aplica).

Para temas e iconos:
- Instala `arc-theme`, `papirus-icon-theme` y `qogir-icon-theme` desde fuentes GTK (o descarga manualmente).
- Instala fuentes: `fonts-cascadia-code`, `fonts-jetbrains-mono`, `fonts-noto-color-emoji`.

Si no están disponibles, descarga manualmente desde GitHub (ej. Nerd Fonts) y colócalas en `~/.local/share/fonts/` o `/usr/share/fonts/`.

## Paso 2: Instalación de Fuentes e Iconos

1. Crea el directorio para fuentes si no existe:
   ```bash
   mkdir -p ~/.local/share/fonts
   ```

2. Descarga e instala Nerd Fonts manualmente:
   - Ve a https://github.com/ryanoasis/nerd-fonts/releases
   - Descarga los ZIP de CascadiaCode, JetBrainsMono y UbuntuMono.
   - Extrae y copia los archivos .ttf/.otf a `~/.local/share/fonts/`.
   - Actualiza el cache de fuentes:
     ```bash
     fc-cache -f ~/.local/share/fonts
     ```

3. Instala iconos:
   - Descarga `papirus-icon-theme` desde https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
   - Extrae a `/usr/share/icons/` o `~/.local/share/icons/`.
   - Instala `arc-theme` y `qogir-icon-theme` de manera similar.

## Paso 3: Copia Manual de Archivos de Configuración

Copia los archivos de configuración desde este repositorio a tus directorios locales.

1. Crea respaldos de tus configuraciones existentes:
   ```bash
   cp -r ~/.config/bspwm ~/.config/bspwm.backup  # Si existe
   cp ~/.zshrc ~/.zshrc.backup  # Si existe
   ```

2. Copia las configuraciones:
   ```bash
   # BSPWM y componentes
   cp -r config/bspwm ~/.config/
   cp -r config/kitty ~/.config/
   cp -r config/dunst ~/.config/  # Si no está en bspwm
   cp -r config/rofi ~/.config/   # Si no está en bspwm
   cp -r config/jgmenu ~/.config/ # Si no está en bspwm

   # Otros
   cp -r config/eww ~/.config/
   cp -r config/geany ~/.config/
   cp -r config/mpd ~/.config/
   cp -r config/ncmpcpp ~/.config/
   cp -r config/nvim ~/.config/
   cp -r config/yazi ~/.config/
   cp -r config/zsh ~/.config/
   cp -r config/clipcat ~/.config/  # Opcional
   cp -r config/paru ~/.config/     # Opcional
   cp -r config/systemd ~/.config/  # Opcional

   # GTK
   cp -r config/gtk-3.0 ~/.config/
   cp home/.gtkrc-2.0 ~/

   # Zsh
   cp home/.zshrc ~/
   ```

3. Asegúrate de que los permisos sean correctos:
   ```bash
   chmod +x ~/.config/bspwm/bin/*
   ```

## Paso 4: Aplicación del Tema

1. Establece el tema activo:
   ```bash
   echo "pyr" > ~/.config/bspwm/.rice
   ```

2. Aplica el tema ejecutando el script de BSPWM:
   ```bash
   ~/.config/bspwm/bin/Theme.sh
   ```

3. Reinicia BSPWM o recarga la configuración:
   ```bash
   bspc wm -r  # O reinicia la sesión
   ```

4. Configura el shell a zsh si no lo es:
   ```bash
   chsh -s /bin/zsh  # O el path correcto
   ```

## Paso 5: Configuración Adicional

- **Wallpaper**: Coloca imágenes en `~/.config/bspwm/rices/pyr/walls/` y ajusta en `theme-config.bash`.
- **MPD**: Inicia el servicio manualmente o con systemd si aplica.
- **Neovim**: Al abrir, instala plugins automáticamente con lazy.nvim.
- **EWW**: Configura widgets según necesidad.
- **Clipcat**: Inicia el daemon si usas clipboard manager.

## Paso 6: Verificación y Ajustes

1. Verifica que las fuentes se carguen:
   ```bash
   fc-list | grep "CascadiaCode"
   ```

2. Prueba componentes:
   - Abre kitty: `kitty`
   - Prueba rofi: `rofi -show run`
   - Verifica iconos en GTK apps.

3. Ajusta colores o fuentes editando `~/.config/bspwm/rices/pyr/theme-config.bash`.
