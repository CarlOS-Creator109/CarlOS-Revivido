#!/bin/sh
#==========================================================
#  aplicar-fix.sh — corrige parpadeo + kernel panic del TUI
#  Corre desde ~/CarlOS:  sh aplicar-fix.sh
#==========================================================
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"

for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    echo "==> $TREE"

    # 1. TUI corregido (anti-parpadeo)
    mkdir -p "$TREE/opt/carlos/gui"
    cp "$HERE/gui/carlos-wm-tui.rb" "$TREE/opt/carlos/gui/carlos-wm-tui.rb"
    echo "   + escritorio TUI (anti-parpadeo)"

    # 2. lanzador carlosdesk que cae a shell (anti-panic)
    cat > "$TREE/usr/bin/carlosdesk" <<'XEOF'
#!/bin/sh
ruby /opt/carlos/gui/carlos-wm-tui.rb
echo ""
echo "Saliste del escritorio. Escribe 'carlosdesk' para volver."
exec /bin/sh
XEOF
    chmod +x "$TREE/usr/bin/carlosdesk"
    echo "   + carlosdesk (cae a shell al salir, sin panic)"
done

echo
echo "==> Fix aplicado. Para arranque directo al escritorio (opcional):"
echo "    for TREE in rootfs iso; do"
echo "        sed -i 's|exec /bin/sh|exec /usr/bin/carlosdesk|' \$TREE/sbin/init"
echo "    done"
echo
echo "==> Luego:  sh build-iso.sh"
