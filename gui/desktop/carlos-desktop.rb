#!/usr/bin/env ruby
# frozen_string_literal: true
#==========================================================
#  carlos-desktop.rb
#  Fondo de escritorio de CarlOS: la gema Ruby en ASCII,
#  centrada. Ruby puro sobre pure-x11.
#
#  Uso:   ruby carlos-desktop.rb
#
#  Dibuja en un PIXMAP y lo fija como background del root
#  window (CWBackPixmap). Asi el fondo PERSISTE aunque el
#  programa termine.
#==========================================================

require 'X11'

GEM = [
  "          ****** ==   ",
  "      ************####-",
  "    ***************####",
  "   *********** *****###",
  " =********-***######## ",
  " ======*******######*  ",
  "##====####****#####*   ",
  "###==########*####**   ",
  " ##=########==####*    ",
  "     -####======##     ",
  "             ##==*     "
].freeze

WORD = [
  "",
  "   ___           _   ___  __",
  "  / __\\__ _ _ __| | /___\\/ _\\",
  " / /  / _` | '__| |//  //\\ \\",
  "/ /__| (_| | |  | / \\_// _\\ \\",
  "\\____/\\__,_|_|  |_\\___/  \\__/"
].freeze

BG     = 0x141013
RED    = 0xe23a56
DARK   = 0x7a1520
LIGHT  = 0xf2a9b5
WHITE  = 0xd8d0cc
FOOTER = 0x4a3a3f

FONT = '-misc-fixed-medium-r-normal--13-120-75-75-c-70-iso8859-1'
FONT_FALLBACK = 'fixed'
CW = 7
CH = 13

dpy = X11::Display.new
screen = dpy.screens.first
root_id = screen.root
depth = (screen.root_depth rescue 24) || 24

geom = dpy.get_geometry(root_id)
sw = geom.width
sh = geom.height

fid = dpy.new_id
begin
  dpy.open_font(fid, FONT)
rescue StandardError
  dpy.open_font(fid, FONT_FALLBACK)
end

pixmap = dpy.create_pixmap(depth, root_id, sw, sh)

def make_gc(dpy, drawable, fid, color, font: true)
  gc = dpy.create_gc(drawable, foreground: color)
  dpy.change_gc(gc, X11::Form::FontMask, [fid]) if font
  gc
end

gc_bg    = make_gc(dpy, pixmap, fid, BG,     font: false)
gc_red   = make_gc(dpy, pixmap, fid, RED)
gc_dark  = make_gc(dpy, pixmap, fid, DARK)
gc_light = make_gc(dpy, pixmap, fid, LIGHT)
gc_white = make_gc(dpy, pixmap, fid, WHITE)
gc_foot  = make_gc(dpy, pixmap, fid, FOOTER)

def gc_for(ch, red, dark, light)
  case ch
  when '*' then red
  when '#', '-' then dark
  when '=' then light
  end
end

dpy.poly_fill_rectangle(pixmap, gc_bg, [0, 0, sw, sh])

gem_w = GEM.map(&:length).max
word_w = WORD.map(&:length).max
gap = 3
total_cols = gem_w + gap + word_w
total_rows = GEM.length
start_col = (sw / CW - total_cols) / 2
start_row = (sh / CH - total_rows) / 2
px0 = start_col * CW
py0 = start_row * CH

GEM.each_with_index do |line, r|
  y = py0 + (r + 1) * CH
  line.chars.each_with_index do |ch, c|
    next if ch == ' '
    gc = gc_for(ch, gc_red, gc_dark, gc_light)
    next unless gc
    dpy.image_text8(pixmap, gc, px0 + c * CW, y, ch)
  end
end

word_px = px0 + (gem_w + gap) * CW
WORD.each_with_index do |line, r|
  next if line.empty?
  y = py0 + (r + 1) * CH
  dpy.image_text8(pixmap, gc_white, word_px, y, line)
end

footer = 'CarlOS 0.2 Alpha  -  Ruby of Sistem'
fx = (sw - footer.length * CW) / 2
fy = sh - CH
dpy.image_text8(pixmap, gc_foot, fx, fy, footer)

dpy.change_window_attributes(root_id,
  values: { X11::Form::CWBackPixmap => pixmap })
dpy.clear_area(false, root_id, 0, 0, 0, 0)
# Refuerzo: ademas de fijar el pixmap como background, lo copiamos
# de una vez al root para que se vea inmediatamente sin esperar un
# Expose. copy_area(src, dst, gc, src_x, src_y, dst_x, dst_y, w, h)
gc_copy = dpy.create_gc(root_id, foreground: BG)
dpy.copy_area(pixmap, root_id, gc_copy, 0, 0, 0, 0, sw, sh)
dpy.flush
sleep 0.3
