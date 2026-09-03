#!/bin/sh
#==========================================================
#  fondo.sh  —  fondo de escritorio minimo para CarlOS
#==========================================================
#  Version simple: color solido carbon con un patron sutil.
#  Si prefieres el logo Ruby dibujado, usa carlos-desktop.rb
#  en su lugar (necesita pure-x11).
#==========================================================

# Color base carbon con un tinte de rejilla en rubi oscuro.
# -mod dibuja un patron tipo tela; con fg oscuro casi no se nota,
# solo da textura para que no sea un negro plano y muerto.
xsetroot -solid "#141013" -fg "#1e1418" -bg "#141013" -mod 8 8

# Nombre del root (algunos programas lo leen)
xsetroot -name "CarlOS Ruby of Sistem"
