#!/bin/sh
#==========================================================
#  instalar.sh — escritorio CarlOS con double buffering
#  (anti-parpadeo) + comando 'startc'. Corre desde ~/CarlOS.
#==========================================================
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"

for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    echo "==> $TREE"

    # escritorio con double buffering (sin parpadeo)
    mkdir -p "$TREE/opt/carlos/gui"
    cp "$HERE/gui/carlos-wm-tui.rb" "$TREE/opt/carlos/gui/carlos-wm-tui.rb"

    # helper C carlosfb (por si se quiere usar el modo diff)
    cp "$HERE/carlosfb" "$TREE/usr/bin/carlosfb"
    chmod +x "$TREE/usr/bin/carlosfb"

    # comando startc (como startx, pero TUI)
    cat > "$TREE/usr/bin/startc" <<'XEOF'
#!/bin/sh
# startc — inicia el escritorio de CarlOS
ruby /opt/carlos/gui/carlos-wm-tui.rb
XEOF
    chmod +x "$TREE/usr/bin/startc"

    # asegurar que el init cae a shell normal (sin panic)
    sed -i 's|exec /usr/bin/carlosdesk|exec /bin/sh|' "$TREE/sbin/init" 2>/dev/null
    sed -i 's|exec ruby /opt/carlos/gui/carlos-wm-tui.rb|exec /bin/sh|' "$TREE/sbin/init" 2>/dev/null

    echo "   + escritorio (double buffering) + startc + carlosfb"
done

echo
echo "==> Listo. Crea la ISO:  sh build-iso.sh"
echo "    En CarlOS: arranca al shell y escribe 'startc'"
