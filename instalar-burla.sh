#!/bin/sh
#==========================================================
#  instalar-burla.sh — burla escalable dinamica de moskau
#
#  El Tetris escribe /tmp/burla.level (0-10) segun que tan
#  mal juegas (altura pila + huecos). burlaplay lo lee EN
#  VIVO y modula: mas nivel = mas rapido + mas desafinado +
#  arpegios mas caoticos. Nivel 10 = caos sin sentido. 😂
#  Todo en C para que las alternancias rapidas sean fluidas.
#==========================================================
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"
for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    echo "==> $TREE"
    for b in burlaplay buzzeroff tuneplay tuneplay-poly; do
        cp "$HERE/bin/$b" "$TREE/usr/bin/$b" && chmod +x "$TREE/usr/bin/$b"
    done
    mkdir -p "$TREE/opt/carlos/sound"
    cp "$HERE/sound/"*.tones "$TREE/opt/carlos/sound/"
    mkdir -p "$TREE/opt/carlos/gui"
    cp "$HERE/gui/carlos-tetris.rb" "$TREE/opt/carlos/gui/carlos-tetris.rb"
    echo "   + burlaplay (C, dinamico) + tetris reactivo"
done
echo
echo "==> Reconstruye:  sh build-iso.sh"
echo "    Juega 'moskau' y apila mal: la burla escala en vivo 😏"
echo "    (nivel escrito en /tmp/burla.level, leido por burlaplay)"
