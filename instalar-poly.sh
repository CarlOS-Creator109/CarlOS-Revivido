#!/bin/sh
# instalar-poly.sh — polifonia simulada en el buzzer
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"
for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    cp "$HERE/bin/tuneplay-poly" "$TREE/usr/bin/tuneplay-poly"
    chmod +x "$TREE/usr/bin/tuneplay-poly"
    mkdir -p "$TREE/opt/carlos/sound"
    cp "$HERE/sound/POLY.tones" "$TREE/opt/carlos/sound/"
    echo "instalado: $TREE"
done
echo
echo "Probar en CarlOS:"
echo "   tuneplay-poly /opt/carlos/sound/POLY.tones"
echo
echo "Para que moskau use polifonia, edita moskau-sound:"
echo "   cambia 'tuneplay \$BUZZER_TONES' por"
echo "          'tuneplay-poly /opt/carlos/sound/POLY.tones'"
echo "Reconstruye: sh build-iso.sh"
