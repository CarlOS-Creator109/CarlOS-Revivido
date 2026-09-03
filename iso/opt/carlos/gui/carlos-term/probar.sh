#!/bin/sh
# Prueba rapida de CarlOS-Term en tu entorno (CoralineOS con Xorg ya corriendo)
#
# Uso:  sh probar.sh
#
set -e

echo "==> Verificando Ruby..."
ruby --version || { echo "Falta ruby. En Arch: sudo pacman -S ruby"; exit 1; }

echo "==> Verificando gema pure-x11..."
if ! ruby -e "require 'X11'" 2>/dev/null; then
    echo "Instalando pure-x11..."
    gem install pure-x11
fi

echo "==> Verificando fuente X11 'fixed'..."
if command -v xlsfonts >/dev/null 2>&1; then
    xlsfonts 2>/dev/null | grep -q fixed || \
        echo "AVISO: no veo la fuente 'fixed'. En Arch: sudo pacman -S xorg-fonts-misc"
fi

echo "==> Lanzando CarlOS-Term (cierra la ventana para salir)..."
ruby carlos-term.rb
