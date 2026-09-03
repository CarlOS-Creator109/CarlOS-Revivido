#!/usr/bin/env ruby
# frozen_string_literal: true
#==========================================================
#  carlos-bar.rb
#  Barra de tareas minima para CarlOS "Ruby of Sistem".
#  Una franja arriba con la marca a la izquierda y el
#  reloj a la derecha. Ruby puro sobre pure-x11.
#
#  Uso:  ruby carlos-bar.rb &
#
#  TWM la respeta como sin-titulo (ver .twmrc: NoTitle
#  incluye "carlos-bar").
#==========================================================

require 'X11'

BAR_H   = 20
BG      = 0x1a1a1a   # carbon
RUBY    = 0xc0392b   # rubi
TEXT    = 0xd8d0cc   # hueso
ACCENT  = 0xe23a56   # rubi brillante

FONT = '-misc-fixed-medium-r-normal--13-120-75-75-c-70-iso8859-1'
FONT_FALLBACK = 'fixed'
CW = 7

dpy = X11::Display.new
screen = dpy.screens.first
root_id = screen.root   # ya es el ID (Integer)
geom = dpy.get_geometry(root_id)
sw = geom.width

# fuente
fid = dpy.new_id
begin
  dpy.open_font(fid, FONT)
rescue StandardError
  dpy.open_font(fid, FONT_FALLBACK)
end

# ventana de la barra: ancho completo, alto BAR_H, pegada arriba
win = X11::Window.create(dpy, 0, 0, sw, BAR_H,
  depth: 24,
  values: {
    X11::Form::CWBackPixel => BG,
    X11::Form::CWOverrideRedirect => 1,   # que el WM no la decore/mueva
    X11::Form::CWEventMask => X11::Form::ExposureMask
  })

# nombre para que TWM la reconozca (NoTitle) por si override no basta
win.change_property(:replace, 'WM_NAME', :string, 8, 'carlos-bar'.bytes)
win.change_property(:replace, 'WM_CLASS', :string, 8, "carlos-bar\0carlos-bar\0".bytes)

# reservar espacio arriba para que las ventanas no la tapen (_NET_WM_STRUT)
# left,right,top,bottom
strut = [0, 0, BAR_H, 0] + [0, 0, 0, 0, 0, sw, 0, 0]
win.change_property(:replace, '_NET_WM_STRUT_PARTIAL', :cardinal, 32,
                    strut.pack('L*').unpack('C*'))
win.change_property(:replace, '_NET_WM_WINDOW_TYPE', :atom, 32,
                    [dpy.atom(:_NET_WM_WINDOW_TYPE_DOCK)].pack('L').unpack('C*'))

win.map

# GCs
gc_bg    = win.create_gc(foreground: BG)
gc_ruby  = win.create_gc(foreground: RUBY)
def with_font(dpy, gc, fid); dpy.change_gc(gc, X11::Form::FontMask, [fid]); gc; end
gc_text   = with_font(dpy, win.create_gc(foreground: TEXT, background: BG), fid)
gc_accent = with_font(dpy, win.create_gc(foreground: ACCENT, background: BG), fid)

BASELINE = BAR_H - 6

def draw(dpy, win, sw, gc_bg, gc_ruby, gc_text, gc_accent)
  # fondo
  win.poly_fill_rectangle(gc_bg, [0, 0, sw, BAR_H])
  # franja rubi de 2px abajo, como acento
  win.poly_fill_rectangle(gc_ruby, [0, BAR_H - 2, sw, 2])

  # marca a la izquierda
  brand = 'CarlOS'
  dpy.image_text8(win.wid, gc_accent, 8, BASELINE, brand)
  sub = ' :: Ruby of Sistem'
  dpy.image_text8(win.wid, gc_text, 8 + brand.length * CW, BASELINE, sub)

  # reloj a la derecha
  clock = Time.now.strftime('%a %d %b  %H:%M')
  cx = sw - clock.length * CW - 8
  dpy.image_text8(win.wid, gc_text, cx, BASELINE, clock)

  dpy.flush
end

draw(dpy, win, sw, gc_bg, gc_ruby, gc_text, gc_accent)

# refrescar el reloj cada 20s y ante Expose
last = Time.now
loop do
  # procesar expose sin bloquear
  while dpy.peek_packet
    pkt = dpy.next_packet
    draw(dpy, win, sw, gc_bg, gc_ruby, gc_text, gc_accent) if pkt.is_a?(X11::Form::Expose)
  end
  if Time.now - last >= 20
    draw(dpy, win, sw, gc_bg, gc_ruby, gc_text, gc_accent)
    last = Time.now
  end
  sleep 0.5
end
