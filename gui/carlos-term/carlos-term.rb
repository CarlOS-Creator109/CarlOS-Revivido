#!/usr/bin/env ruby
# frozen_string_literal: true
#
# ==========================================================
#  CarlOS-Term v0.1
#  Emulador de terminal para CarlOS "Ruby of Sistem"
#  Escrito en Ruby puro sobre pure-x11 (sin bindings C).
# ==========================================================
#
#  Corre un shell dentro de un pseudo-terminal (PTY) y lo
#  pinta en una ventana X11: grilla de caracteres monoespacio,
#  cursor de bloque, y un parser mínimo de secuencias ANSI
#  (colores SGR + borrado de pantalla/linea + posicionar cursor).
#
#  Uso:
#     ruby carlos-term.rb            # arranca /bin/sh (o $SHELL)
#     SHELL=/bin/bash ruby carlos-term.rb
#
#  Requiere: gem install pure-x11
# ==========================================================

require 'X11'
require 'pty'
require 'io/console'

module CarlOS
  # -- Paleta: los 8 colores ANSI base + brillantes, en 0xRRGGBB --
  # El fondo/primer plano por defecto guiñan al branding rojo de CarlOS.
  ANSI_COLORS = [
    0x1a1a1a, # 0 negro
    0xc0392b, # 1 rojo   (rubi CarlOS)
    0x27ae60, # 2 verde
    0xd4a017, # 3 amarillo
    0x3498db, # 4 azul
    0x9b59b6, # 5 magenta
    0x1abc9c, # 6 cian
    0xd8d0cc, # 7 blanco (hueso)
    # brillantes
    0x555555, # 8  gris
    0xe74c3c, # 9  rojo brillante
    0x2ecc71, # 10 verde brillante
    0xf1c40f, # 11 amarillo brillante
    0x5dade2, # 12 azul brillante
    0xbb8fce, # 13 magenta brillante
    0x48c9b0, # 14 cian brillante
    0xffffff  # 15 blanco brillante
  ].freeze

  DEFAULT_FG = 7
  DEFAULT_BG = 0

  # Fuente X11 monoespacio clasica; casi siempre presente. Si no,
  # se intenta un fallback mas generico.
  FONT_PRIMARY  = '-misc-fixed-medium-r-normal--13-120-75-75-c-70-iso8859-1'
  FONT_FALLBACK = 'fixed'

  class Cell
    attr_accessor :ch, :fg, :bg
    def initialize(ch = ' ', fg = DEFAULT_FG, bg = DEFAULT_BG)
      @ch = ch; @fg = fg; @bg = bg
    end
  end

  # ----------------------------------------------------------
  # El "modelo": una grilla de celdas con cursor y estado SGR.
  # Aqui vive el parser ANSI. No sabe nada de X11.
  # ----------------------------------------------------------
  class Screen
    attr_reader :cols, :rows, :cx, :cy

    def initialize(cols, rows)
      @cols = cols; @rows = rows
      @cx = 0; @cy = 0
      @cur_fg = DEFAULT_FG; @cur_bg = DEFAULT_BG
      @grid = Array.new(rows) { Array.new(cols) { Cell.new } }
      @dirty = true
    end

    def dirty? = @dirty
    def clear_dirty = (@dirty = false)
    def mark_dirty = (@dirty = true)
    def cell(x, y) = @grid[y][x]

    def resize(cols, rows)
      new_grid = Array.new(rows) { Array.new(cols) { Cell.new } }
      [rows, @rows].min.times do |y|
        [cols, @cols].min.times { |x| new_grid[y][x] = @grid[y][x] }
      end
      @grid = new_grid; @cols = cols; @rows = rows
      @cx = [@cx, cols - 1].min; @cy = [@cy, rows - 1].min
      mark_dirty
    end

    # Alimenta bytes crudos del PTY. Mantiene un buffer para
    # secuencias de escape partidas entre lecturas.
    def feed(bytes)
      @pending ||= +''
      @pending << bytes
      consume
      mark_dirty
    end

    private

    def consume
      i = 0
      buf = @pending
      while i < buf.length
        c = buf[i]
        if c == "\e"
          # necesitamos al menos el introductor
          if i + 1 >= buf.length
            break # esperar mas bytes
          elsif buf[i + 1] == '['
            # CSI ... letra_final
            m = buf[i..].match(/\A\e\[([0-9;?]*)([A-Za-z])/)
            if m.nil?
              break # secuencia incompleta, esperar
            else
              handle_csi(m[1], m[2])
              i += m[0].length
              next
            end
          else
            # otras secuencias de escape de 2 bytes: las saltamos
            i += 2
            next
          end
        else
          put_char(c)
          i += 1
        end
      end
      @pending = buf[i..] || +''
    end

    def put_char(c)
      case c
      when "\n" then line_feed
      when "\r" then @cx = 0
      when "\b" then @cx = [@cx - 1, 0].max
      when "\t"
        @cx = [((@cx / 8) + 1) * 8, @cols - 1].min
      when "\a" then nil # bell: ignorar por ahora
      else
        return if c.ord < 32 # otros control chars: ignorar
        if @cx >= @cols
          @cx = 0; line_feed
        end
        cell = @grid[@cy][@cx]
        cell.ch = c; cell.fg = @cur_fg; cell.bg = @cur_bg
        @cx += 1
      end
    end

    def line_feed
      @cy += 1
      if @cy >= @rows
        @grid.shift
        @grid.push(Array.new(@cols) { Cell.new })
        @cy = @rows - 1
      end
    end

    def handle_csi(params, final)
      args = params.split(';').map { |x| x.empty? ? nil : x.to_i }
      case final
      when 'm' then set_graphics(args)
      when 'H', 'f'
        @cy = [(args[0] || 1) - 1, @rows - 1].min
        @cx = [(args[1] || 1) - 1, @cols - 1].min
      when 'A' then @cy = [@cy - (args[0] || 1), 0].max
      when 'B' then @cy = [@cy + (args[0] || 1), @rows - 1].min
      when 'C' then @cx = [@cx + (args[0] || 1), @cols - 1].min
      when 'D' then @cx = [@cx - (args[0] || 1), 0].max
      when 'J' then erase_display(args[0] || 0)
      when 'K' then erase_line(args[0] || 0)
      end
    end

    def set_graphics(args)
      args = [0] if args.empty?
      idx = 0
      while idx < args.length
        n = args[idx] || 0
        case n
        when 0 then @cur_fg = DEFAULT_FG; @cur_bg = DEFAULT_BG
        when 1 then @cur_fg |= 8 if @cur_fg < 8 # bold -> brillante
        when 30..37 then @cur_fg = n - 30
        when 40..47 then @cur_bg = n - 40
        when 90..97 then @cur_fg = (n - 90) + 8
        when 100..107 then @cur_bg = (n - 100) + 8
        when 38, 48
          # 256-color: ESC[38;5;Nm  -> lo mapeamos a los 16 si N<16
          if args[idx + 1] == 5
            col = args[idx + 2] || 0
            col = col < 16 ? col : DEFAULT_FG
            n == 38 ? @cur_fg = col : @cur_bg = col
            idx += 2
          end
        end
        idx += 1
      end
    end

    def erase_display(mode)
      case mode
      when 2, 3
        @grid.each { |row| row.each { |cell| cell.ch = ' '; cell.bg = @cur_bg } }
        @cx = 0; @cy = 0
      when 0 # desde cursor al final
        (@cy...@rows).each do |y|
          (y == @cy ? @cx : 0).upto(@cols - 1) { |x| @grid[y][x] = Cell.new(' ', DEFAULT_FG, @cur_bg) }
        end
      end
    end

    def erase_line(mode)
      row = @grid[@cy]
      case mode
      when 0 then (@cx...@cols).each { |x| row[x] = Cell.new(' ', DEFAULT_FG, @cur_bg) }
      when 1 then (0..@cx).each { |x| row[x] = Cell.new(' ', DEFAULT_FG, @cur_bg) }
      when 2 then (0...@cols).each { |x| row[x] = Cell.new(' ', DEFAULT_FG, @cur_bg) }
      end
    end
  end

  # ----------------------------------------------------------
  # La "vista + controlador": ventana X11, dibuja la Screen,
  # captura teclas y las manda al PTY. Aqui vive todo lo de X11.
  # ----------------------------------------------------------
  class Term
    def initialize(cols: 80, rows: 24)
      @dpy = X11::Display.new
      @screen_x = @dpy.screens.first
      @root = @screen_x.root

      open_font
      # ancho/alto de celda a partir de la fuente (fixed 13px: ~7x13)
      @cw = 7
      @ch = 13
      @pad = 4

      @cols = cols; @rows = rows
      @screen = Screen.new(cols, rows)

      w = cols * @cw + @pad * 2
      h = rows * @ch + @pad * 2

      @win = X11::Window.create(@dpy, 0, 0, w, h,
        depth: 24,
        values: {
          X11::Form::CWBackPixel => ANSI_COLORS[DEFAULT_BG],
          X11::Form::CWEventMask =>
            (X11::Form::ExposureMask |
             X11::Form::KeyPressMask |
             X11::Form::StructureNotifyMask)
        })

      set_title('CarlOS-Term')
      @win.map

      # Un GC por color de primer plano, cacheado.
      @gc_cache = {}
      @gc_bg = @win.create_gc(foreground: ANSI_COLORS[DEFAULT_BG])

      start_shell
    end

    def set_title(str)
      @win.change_property(:replace, 'WM_NAME', :string, 8, str.bytes)
      @win.change_property(:replace, '_NET_WM_NAME', :string, 8, str.bytes)
      # WM_CLASS: "instance\0class\0" — deja que el WM (rubywm) y
      # herramientas como xdotool identifiquen y enruten la ventana.
      wmclass = "carlos-term\0CarlOS-Term\0"
      @win.change_property(:replace, 'WM_CLASS', :string, 8, wmclass.bytes)
    end

    def open_font
      @fid = @dpy.new_id
      begin
        @dpy.open_font(@fid, FONT_PRIMARY)
      rescue StandardError
        @dpy.open_font(@fid, FONT_FALLBACK)
      end
    end

    def gc_for(fg)
      @gc_cache[fg] ||= begin
        gc = @win.create_gc(foreground: ANSI_COLORS[fg], background: ANSI_COLORS[DEFAULT_BG])
        @dpy.change_gc(gc, X11::Form::FontMask, [@fid])
        gc
      end
    end

    def start_shell
      shell = ENV['SHELL'] || '/bin/sh'
      @pty_out, @pty_in, @pid = PTY.spawn(shell)
      # Ajustar tamano del PTY a la grilla (filas, columnas)
      begin
        @pty_out.winsize = [@rows, @cols]
      rescue StandardError
        nil
      end
    end

    # ---- dibujo ----
    def redraw
      # fondo completo
      @win.poly_fill_rectangle(@gc_bg, [0, 0, @cols * @cw + @pad * 2, @rows * @ch + @pad * 2])
      @rows.times do |y|
        # agrupar por runs del mismo color de fondo seria mas eficiente;
        # para v0.1 pintamos celda a celda (suficiente en 80x24).
        line = +''
        run_fg = nil; run_x = 0
        @cols.times do |x|
          cell = @screen.cell(x, y)
          # pintar fondo si difiere del default
          if cell.bg != DEFAULT_BG
            bggc = gc_for(cell.bg) # reutilizamos como color de relleno
            @win.poly_fill_rectangle(bg_fill_gc(cell.bg),
              [@pad + x * @cw, @pad + y * @ch, @cw, @ch])
          end
        end
        # texto: una pasada por color
        draw_text_line(y)
      end
      draw_cursor
      @dpy.flush
    end

    def bg_fill_gc(bg)
      (@bg_gc_cache ||= {})[bg] ||= @win.create_gc(foreground: ANSI_COLORS[bg])
    end

    def draw_text_line(y)
      x = 0
      while x < @cols
        fg = @screen.cell(x, y).fg
        # acumular caracteres contiguos con el mismo fg
        run = +''
        start = x
        while x < @cols && @screen.cell(x, y).fg == fg
          run << @screen.cell(x, y).ch
          x += 1
        end
        # saltar runs que son solo espacios (el fondo ya esta pintado)
        next if run.each_char.all? { |c| c == ' ' }
        px = @pad + start * @cw
        py = @pad + y * @ch + (@ch - 3) # baseline aprox
        @dpy.image_text8(@win.wid, gc_for(fg), px, py, run)
      end
    end

    def draw_cursor
      cx = @screen.cx; cy = @screen.cy
      px = @pad + cx * @cw
      py = @pad + cy * @ch
      # cursor de bloque: rectangulo relleno color rubi CarlOS
      @win.poly_fill_rectangle(bg_fill_gc(1), [px, py, @cw, @ch])
      # re-dibujar el caracter bajo el cursor en color de fondo
      cell = @screen.cell(cx, cy)
      unless cell.ch == ' '
        @dpy.image_text8(@win.wid, gc_for(DEFAULT_BG), px, py + (@ch - 3), cell.ch)
      end
    end

    # ---- teclado ----
    def update_keymap
      reply = @dpy.get_keyboard_mapping
      @per = reply.keysyms_per_keycode
      @min_kc = @dpy.display_info.min_keycode
      @keymap = reply.keysyms
    end

    def keysym_to_bytes(event)
      update_keymap unless @keymap
      base = (event.detail - @min_kc) * @per
      shift = (event.state & 1) != 0
      ctrl  = (event.state & 4) != 0
      sym = @keymap[base + (shift ? 1 : 0)]
      sym = @keymap[base] if sym.nil? || sym.zero?
      return nil if sym.nil? || sym.zero?

      # teclas especiales
      case sym
      when 0xff0d, 0xff8d then return "\r"          # Return
      when 0xff08 then return "\x7f"                 # Backspace
      when 0xff09 then return "\t"                   # Tab
      when 0xff1b then return "\e"                    # Escape
      when 0xff51 then return "\e[D"                  # Left
      when 0xff53 then return "\e[C"                  # Right
      when 0xff52 then return "\e[A"                  # Up
      when 0xff54 then return "\e[B"                  # Down
      end

      if sym < 0x100
        ch = sym.chr(Encoding::ISO_8859_1)
        if ctrl && /[a-zA-Z]/.match?(ch)
          return (ch.downcase.ord - 'a'.ord + 1).chr # Ctrl-A..Z
        end
        return ch
      end
      nil
    end

    # ---- loop principal ----
    #
    # pure-x11 corre un thread interno de lectura que llena una cola
    # (@rqueue). Aqui: drenamos esa cola sin bloquear con peek_packet,
    # y hacemos IO.select solo sobre el PTY para no quemar CPU.
    def run
      update_keymap
      @running = true

      while @running
        # 1) leer todo lo disponible del PTY
        drain_pty

        # 2) procesar eventos X en cola (sin bloquear)
        while @dpy.peek_packet
          handle_event(@dpy.next_packet)
        end

        # 3) redibujar si algo cambio
        if @screen.dirty?
          redraw
          @screen.clear_dirty
        end

        # 4) dormir hasta que el PTY tenga datos (o timeout corto para
        #    seguir atendiendo eventos X que llegan por el otro thread)
        begin
          IO.select([@pty_out], nil, nil, 0.02)
        rescue StandardError
          sleep 0.02
        end
      end

      cleanup
    end

    def drain_pty
      loop do
        data = @pty_out.read_nonblock(4096)
        break if data.nil? || data.empty?
        @screen.feed(data)
      end
    rescue IO::WaitReadable, Errno::EAGAIN
      # nada mas por ahora
    rescue EOFError, Errno::EIO
      @running = false
    end

    def handle_event(pkt)
      case pkt
      when X11::Form::Expose
        @screen.mark_dirty
      when X11::Form::KeyPress
        bytes = keysym_to_bytes(pkt)
        @pty_in.write(bytes) if bytes
      when X11::Form::ConfigureNotify
        new_cols = [(pkt.width - @pad * 2) / @cw, 1].max
        new_rows = [(pkt.height - @pad * 2) / @ch, 1].max
        if new_cols != @cols || new_rows != @rows
          @cols = new_cols; @rows = new_rows
          @screen.resize(new_cols, new_rows)
          begin; @pty_out.winsize = [@rows, @cols]; rescue StandardError; end
        end
      when X11::Form::DestroyNotify
        @running = false
      end
    end

    def cleanup
      Process.kill('TERM', @pid) rescue nil
      @dpy.close rescue nil
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  CarlOS::Term.new.run
end
