#!/bin/sh
#==========================================================
#  iniciar-gui.sh
#  Arranca el entorno grafico de CarlOS "Ruby of Sistem"
#  (TWM + fondo Ruby + barra + CarlOS-Term) sobre Xorg.
#==========================================================
#
#  Uso desde una TTY (sin X corriendo):
#     sh iniciar-gui.sh
#
#  Copia la sesion a ~/.xinitrc y hace startx. Si prefieres
#  hacerlo a mano, mira gui/xinitrc.
#==========================================================

set -e

GUI_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Verificando dependencias..."

# Ruby
command -v ruby >/dev/null 2>&1 || {
    echo "ERROR: falta ruby. En Arch: sudo pacman -S ruby"; exit 1; }

# gema pure-x11
if ! ruby -e "require 'X11'" 2>/dev/null; then
    echo "  instalando gema pure-x11..."
    gem install pure-x11
fi

# Xorg + startx
command -v startx >/dev/null 2>&1 || {
    echo "ERROR: falta startx. En Arch: sudo pacman -S xorg-xinit xorg-server"; exit 1; }

# TWM
command -v twm >/dev/null 2>&1 || {
    echo "ERROR: falta twm. En Arch: sudo pacman -S xorg-twm"; exit 1; }

# xsetroot (para el fondo simple)
command -v xsetroot >/dev/null 2>&1 || \
    echo "  aviso: falta xsetroot (xorg-xsetroot); el fondo simple no funcionara,"
    echo "         pero el fondo con logo Ruby (carlos-desktop.rb) si."

echo "==> Todo listo. Lanzando sesion grafica..."
echo "    (click derecho en el escritorio = menu; cerrar TWM = salir)"

# Construir un xinitrc temporal con las rutas absolutas de este arbol
XINITRC="$(mktemp)"
cat > "$XINITRC" <<EOF
#!/bin/sh
# fondo con logo Ruby (usa fondo.sh si prefieres el simple)
ruby "$GUI_DIR/desktop/carlos-desktop.rb" &
# barra de tareas
ruby "$GUI_DIR/desktop/carlos-bar.rb" &
# terminal de arranque
ruby "$GUI_DIR/carlos-term/carlos-term.rb" &
# window manager (mantiene la sesion viva)
exec twm -f "$GUI_DIR/desktop/twmrc"
EOF

startx "$XINITRC"
rm -f "$XINITRC"
