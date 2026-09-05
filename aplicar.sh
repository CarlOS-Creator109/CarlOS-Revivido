#!/bin/sh
# buzzer por defecto hasta 0.4
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"
for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    cp "$HERE/bin/moskau-sound" "$TREE/usr/bin/moskau-sound"
    chmod +x "$TREE/usr/bin/moskau-sound"
    echo "actualizado: $TREE"
done
echo "Reconstruye: sh build-iso.sh"
