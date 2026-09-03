# Entorno gráfico de CarlOS — "Ruby of Sistem"

Xorg + TWM como base, y encima una capa propia en **Ruby puro** (pure-x11):
fondo de escritorio, barra de tareas y CarlOS-Term. Sin bindings C, todo habla
el protocolo X11 directo por socket — pensado para la Sony Vaio.

## Piezas

```
gui/
├── iniciar-gui.sh          arranca todo (verifica deps + startx)
├── xinitrc                 sesión de ejemplo (para copiar a ~/.xinitrc)
├── carlos-term/
│   └── carlos-term.rb      la terminal (PTY + X11 + parser ANSI)
└── desktop/
    ├── carlos-desktop.rb   fondo: gema Ruby dibujada, fijada como wallpaper
    ├── carlos-bar.rb       barra de tareas: marca + reloj
    ├── fondo.sh            fondo alternativo simple (xsetroot, color sólido)
    └── twmrc               config de TWM con estilo CarlOS (rubí)
```

## Arranque rápido

Desde una TTY (sin X corriendo todavía):

```sh
cd ~/CarlOS/gui
sh iniciar-gui.sh
```

Eso verifica que tengas Ruby, la gema `pure-x11`, Xorg y TWM; instala la gema
si falta; y lanza la sesión con `startx`.

## Arranque manual

Si ya sabes lo que haces, copia el `xinitrc` y edítalo:

```sh
cp ~/CarlOS/gui/xinitrc ~/.xinitrc
# ajusta las rutas $HOME/CarlOS/gui/... si hace falta
startx
```

## Cómo se usa

- **Click derecho en el escritorio** → menú de CarlOS (nueva terminal, refrescar
  fondo, operaciones de ventana, salir).
- **Click izquierdo en el escritorio** → menú de ventanas abiertas.
- **Barra de título de una ventana**: arrastrar mueve, botón central sube/baja,
  botón derecho abre operaciones.
- **Salir de la sesión**: menú → "Salir de X" (o cerrar TWM).

## Dependencias (Arch / CoralineOS)

```sh
sudo pacman -S ruby xorg-server xorg-xinit xorg-twm xorg-xsetroot xorg-fonts-misc
gem install pure-x11
```

La fuente `fixed` (de `xorg-fonts-misc`) es la que usan la terminal, la barra y
el fondo. Casi siempre ya está en cualquier instalación con Xorg.

## Elegir el fondo

Por defecto `iniciar-gui.sh` usa **carlos-desktop.rb** (la gema Ruby dibujada).
Si prefieres un fondo liso más ligero, cambia esa línea por `desktop/fondo.sh`.

## Estado y pendientes

Funciona: terminal (shell real, colores ANSI, teclado, redimensionable), barra
(marca + reloj), fondo (gema Ruby como wallpaper), y TWM ordenando las ventanas.

Roadmap:
- Barra: mostrar la lista de ventanas abiertas (ahora solo marca + reloj).
- Fondo: opción de imagen (PNG) además del ASCII.
- Terminal: scrollback, más secuencias ANSI (para `vi`/`htop`), copiar/pegar.
- Integrar el logo Ruby también en el boot ROM del initramfs.
- A futuro: reemplazar TWM por un WM propio en Ruby (rubywm como base).

## Nota

El entorno se probó por piezas en Xorg. La terminal y la barra se verificaron
con capturas reales; el fondo usa las APIs correctas de wallpaper X11
(pixmap + CWBackPixmap + copy_area). En tu Vaio con Xorg nativo todo corre
junto bajo TWM.
