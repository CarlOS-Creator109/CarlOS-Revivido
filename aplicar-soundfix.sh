#!/bin/sh
#==========================================================
#  aplicar-soundfix.sh — arregla:
#   1. moskau-sound: quita el check que bloqueaba el buzzer
#   2. buzzeroff: apaga el buzzer al parar (--stop limpio)
#   3. carlosbeep: lo mueve DESPUES del mount de /dev en el init
#      (sonaba antes de que existiera /dev/console)
#  Corre desde ~/CarlOS:  sh aplicar-soundfix.sh
#==========================================================
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"

for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    echo "==> $TREE"

    # 1 y 2: moskau-sound + buzzeroff
    cp "$HERE/bin/moskau-sound" "$TREE/usr/bin/moskau-sound"
    cp "$HERE/bin/buzzeroff"    "$TREE/usr/bin/buzzeroff"
    chmod +x "$TREE/usr/bin/moskau-sound" "$TREE/usr/bin/buzzeroff"
    echo "   + moskau-sound (sin check bloqueante) + buzzeroff"

    # 3: reordenar carlosbeep en el init (despues de devtmpfs)
    if [ -f "$TREE/sbin/init" ]; then
        # quitar carlosbeep de donde este
        sed -i '/carlosbeep/d' "$TREE/sbin/init"
        # reinsertar despues del mount de devtmpfs
        if grep -q 'mount -t devtmpfs' "$TREE/sbin/init"; then
            sed -i '/mount -t devtmpfs/a /usr/bin/carlosbeep 2>/dev/null' "$TREE/sbin/init"
            echo "   + carlosbeep movido despues de devtmpfs"
        else
            # si no hay devtmpfs, agregarlo tambien
            sed -i '1a mount -t devtmpfs devtmpfs /dev 2>/dev/null\n/usr/bin/carlosbeep 2>/dev/null' "$TREE/sbin/init"
            echo "   + devtmpfs + carlosbeep agregados"
        fi
    fi
done

echo
echo "==> Verifica el init:"
echo "    head -6 iso/sbin/init"
echo "==> Reconstruye:  sh build-iso.sh"
