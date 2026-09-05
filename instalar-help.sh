#!/bin/sh
# instalar-help.sh — help horizontal de CarlOS
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"
for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    cp "$HERE/help" "$TREE/usr/bin/help"
    chmod +x "$TREE/usr/bin/help"
    echo "instalado: $TREE"
done
echo "Reconstruye: sh build-iso.sh"
echo "En CarlOS: escribe 'help'"
