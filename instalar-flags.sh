#!/bin/sh
#==========================================================
#  instalar-flags.sh — moskau con -m (mono) y -v (volumen)
#  · tuneplay v2: soporta volumen PWM (1-4)
#  · moskau -m         : melodia mono limpia (sin burla)
#  · moskau -v/-vv/-vvv: baja el volumen (medio/bajo/susurro)
#  · combinables:  moskau -m -vv
#==========================================================
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"
for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    cp "$HERE/bin/tuneplay" "$TREE/usr/bin/tuneplay"
    chmod +x "$TREE/usr/bin/tuneplay"
    mkdir -p "$TREE/opt/carlos/gui"
    cp "$HERE/gui/carlos-tetris.rb" "$TREE/opt/carlos/gui/carlos-tetris.rb"
    echo "actualizado: $TREE"
done
echo
echo "==> Reconstruye:  sh build-iso.sh"
echo "    moskau           normal (con burla)"
echo "    moskau -m        mono limpio (sin burla)"
echo "    moskau -v        volumen medio"
echo "    moskau -vv       volumen bajo"
echo "    moskau -vvv      susurro"
echo "    moskau -m -vv    mono + bajito (salva-oidos) 😌"
