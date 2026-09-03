# CarlOS-Term

Emulador de terminal para **CarlOS "Ruby of Sistem"**, escrito en Ruby puro
sobre [pure-x11](https://github.com/vidarh/ruby-x11) — sin bindings C, habla
el protocolo X11 directo por socket. Pensado para correr bajo Xorg + un WM en
Ruby (rubywm) en la Sony Vaio, aunque funciona en cualquier X11.

## Qué hace (v0.1)

- Corre un shell dentro de un pseudo-terminal (PTY) y lo pinta en una ventana X11.
- Grilla de caracteres monoespacio (fuente `fixed` de X11, 7x13).
- Cursor de bloque en **rojo rubí** (el color de CarlOS).
- Parser mínimo de secuencias ANSI:
  - Colores SGR (`ESC[30..37m`, `ESC[90..97m`, fondos, negrita, reset).
  - 256-color degradado a los 16 base (`ESC[38;5;Nm`).
  - Movimiento de cursor (`H`, `A`, `B`, `C`, `D`).
  - Borrado de pantalla y línea (`J`, `K`).
- Teclado: teclas normales, Return, Backspace, Tab, Escape, flechas, y Ctrl-A..Z.
- Redimensionable: al cambiar el tamaño de la ventana, reajusta la grilla y
  avisa al PTY (`TIOCSWINSZ`), así los programas dentro saben las nuevas medidas.

## Requisitos

```sh
gem install pure-x11
```

Necesita la fuente X11 `fixed` (viene en `xorg-fonts-misc` / `xfonts-base`),
que casi siempre está presente en cualquier instalación con Xorg.

## Uso

```sh
ruby carlos-term.rb              # arranca $SHELL, o /bin/sh
SHELL=/bin/bash ruby carlos-term.rb
```

## Integración con rubywm

CarlOS-Term es un cliente X11 normal, así que cualquier WM lo gestiona. Con
rubywm, lo típico es lanzarlo desde `sxhkd` con un atajo, por ejemplo en
`sxhkdrc`:

```
super + Return
    ruby /ruta/a/carlos-term.rb
```

La ventana se identifica con `WM_CLASS = carlos-term / CarlOS-Term`, para que
puedas hacerle reglas en el WM.

## Pendiente (roadmap)

- Fuente propia / TrueType vía skrift-x11 (para no depender de `fixed`).
- Scrollback (historial hacia arriba).
- Más secuencias ANSI (regiones de scroll, modos de cursor, títulos OSC).
- Selección y copiar/pegar por X selections.
- Optimizar el redraw (dibujar solo celdas sucias, no toda la pantalla).
- Logo Ruby de CarlOS como splash al abrir.

## Notas de diseño

El código separa el **modelo** (`Screen`: la grilla + parser ANSI, no sabe de
X11) de la **vista/controlador** (`Term`: ventana, dibujo, teclado). Eso hace
fácil, más adelante, cambiar el backend de dibujo (por ejemplo a framebuffer
directo) sin tocar la lógica de la terminal.
