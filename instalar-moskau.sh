#!/bin/sh
#==========================================================
#  instalar-moskau.sh — Tetris EGT + comando 'moskau'
#  Corre desde ~/CarlOS:  sh instalar-moskau.sh
#==========================================================
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"

for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    echo "==> $TREE"
    mkdir -p "$TREE/opt/carlos/gui"
    cp "$HERE/gui/carlos-tetris.rb" "$TREE/opt/carlos/gui/carlos-tetris.rb"
    # comando 'moskau' que lanza el tetris
    cat > "$TREE/usr/bin/moskau" <<'XEOF'
#!/bin/sh
# moskau — Tetris de CarlOS con estilo EGT
exec ruby /opt/carlos/gui/carlos-tetris.rb
XEOF
    chmod +x "$TREE/usr/bin/moskau"
    echo "   + tetris + comando 'moskau'"
done

echo
echo "==> Listo. En CarlOS escribe:  moskau"
echo "    (para agregarlo al menu del EGT, edita @apps en carlos-wm-tui.rb)"
