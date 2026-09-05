#!/bin/sh
#==========================================================
#  instalar-audio.sh — sistema de audio de CarlOS + moskau
#  Corre desde ~/CarlOS:  sh instalar-audio.sh
#==========================================================
CARLOS="$HOME/CarlOS"
HERE="$(cd "$(dirname "$0")" && pwd)"

# --- copiar aplay + libasound de tu CoralineOS (para ALSA) ---
echo "==> Copiando stack ALSA (aplay + libasound)..."
if [ -f "$CARLOS/carlos-xorg/copiar-con-deps.sh" ]; then
    for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
        sh "$CARLOS/carlos-xorg/copiar-con-deps.sh" "$TREE" \
            /usr/bin/aplay 2>/dev/null
    done
else
    echo "   (aviso: copiar-con-deps.sh no encontrado; copia aplay a mano)"
fi
# datos de ALSA (config de tarjetas)
for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    cp -a /usr/share/alsa "$TREE/usr/share/" 2>/dev/null
    cp -a /usr/lib/alsa-lib "$TREE/usr/lib/" 2>/dev/null
done

for TREE in "$CARLOS/rootfs" "$CARLOS/iso"; do
    [ -d "$TREE" ] || continue
    echo "==> $TREE"
    # tablas de tonos + WAV
    mkdir -p "$TREE/opt/carlos/sound"
    cp "$HERE/sound/"*.tones "$TREE/opt/carlos/sound/"
    cp "$HERE/sound/korobeiniki_mix.wav" "$TREE/opt/carlos/sound/"
    # players
    cp "$HERE/bin/tuneplay" "$TREE/usr/bin/tuneplay"
    cp "$HERE/bin/moskau-sound" "$TREE/usr/bin/moskau-sound"
    chmod +x "$TREE/usr/bin/tuneplay" "$TREE/usr/bin/moskau-sound"
    # tetris con audio
    mkdir -p "$TREE/opt/carlos/gui"
    cp "$HERE/gui/carlos-tetris.rb" "$TREE/opt/carlos/gui/carlos-tetris.rb"
    # comando moskau (por si no existe)
    cat > "$TREE/usr/bin/moskau" <<'XEOF'
#!/bin/sh
exec ruby /opt/carlos/gui/carlos-tetris.rb
XEOF
    chmod +x "$TREE/usr/bin/moskau"
    echo "   + tonos + WAV + tuneplay + moskau-sound + tetris"
done

echo
echo "==> Listo. Reconstruye:  sh build-iso.sh"
echo "    En CarlOS:"
echo "      moskau              -> tetris CON musica (detecta hw)"
echo "      moskau-sound        -> solo la musica (buzzer+ALSA segun haya)"
echo "      moskau-sound --alsa -> forzar ALSA"
echo "      tuneplay /opt/carlos/sound/N1.tones  -> melodia por buzzer"
