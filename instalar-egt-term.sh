#!/bin/sh
#==========================================================
#  instalar-egt-term.sh — EGT con TERMINAL FUNCIONAL
#  La app "Terminal" (tecla 1) abre un shell ash REAL dentro
#  de una ventana del escritorio. Escribes comandos ahi.
#  Ctrl-] suelta el foco de la terminal (vuelve al WM).
#==========================================================
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"
for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    mkdir -p "$TREE/opt/carlos/gui"
    cp "$HERE/gui/carlos-wm-tui.rb" "$TREE/opt/carlos/gui/carlos-wm-tui.rb"
    echo "actualizado: $TREE"
done
echo
echo "==> Reconstruye:  sh build-iso.sh"
echo "    En CarlOS:  startc  (o carlosdesk)"
echo "    Tecla 1 = abrir terminal ash dentro de una ventana"
echo "    Escribe comandos normalmente; Ctrl-] suelta el foco"
