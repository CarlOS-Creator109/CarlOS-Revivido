#!/bin/sh
#==========================================================
#  instalar-buztts.sh — buztts como comando Unix real
#  Lee de: argumentos, stdin (pipe), o archivo (-f).
#==========================================================
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"
for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    cp "$HERE/bin/buztts" "$TREE/usr/bin/buztts"
    chmod +x "$TREE/usr/bin/buztts"
    echo "instalado: $TREE"
done
echo
echo "buztts ya es comando real. En CarlOS:"
echo '   buztts "Bienvenido a CarlOS"'
echo '   echo "hola mundo" | buztts'
echo '   buztts -f /etc/motd'
echo '   scfetch | buztts -q          (subtitula la salida de scfetch)'
echo '   buztts -h                    (ayuda)'
echo "Reconstruye: sh build-iso.sh"
