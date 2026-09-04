#!/usr/bin/env ruby
# frozen_string_literal: true
#==========================================================
#  carlos-wm-tui.rb — Escritorio TUI de CarlOS CON VENTANAS
#  "Ruby of Sistem". Estilo Turbo Vision: varias ventanas
#  apiladas, una activa, mover/cerrar/cambiar. Ruby+ANSI puro.
#
#  Teclas:
#    F1..F5 / 1..5  abrir apps        TAB  cambiar ventana activa
#    flechas        mover ventana activa
#    c              cerrar ventana activa
#    q              salir del escritorio
#==========================================================

module CarlOS
  ESC = "\e"
  @@buf = nil                      # buffer de frame (double buffering)
  def self.buf_start = (@@buf = +"")
  def self.buf_flush
    if @@buf
      $stdout.write("#{ESC}[H" + @@buf)   # UN solo write: cursor home + frame
      $stdout.flush
      @@buf = nil
    end
  end
  def self.emit(s) = (@@buf ? @@buf << s : print(s))
  def self.cls   = print("#{ESC}[2J#{ESC}[H")
  def self.at(r,c) = emit("#{ESC}[#{r};#{c}H")
  def self.hide  = print("#{ESC}[?25l")
  def self.show  = print("#{ESC}[?25h")

  RED="#{ESC}[38;5;196m"; DARK="#{ESC}[38;5;88m"; LIGHT="#{ESC}[38;5;217m"
  WHITE="#{ESC}[97m"; DIM="#{ESC}[38;5;240m"; GREY="#{ESC}[38;5;245m"
  BGRUBY="#{ESC}[48;5;88m"; BGBAR="#{ESC}[48;5;236m"; BGACT="#{ESC}[48;5;52m"
  RST="#{ESC}[0m"

  # -------- Una ventana --------
  class Window
    attr_accessor :title, :top, :left, :w, :h, :lines, :id
    def initialize(id, title, top, left, w, h, lines)
      @id=id; @title=title; @top=top; @left=left; @w=w; @h=h; @lines=lines
    end

    def draw(active)
      bcol = active ? RED : DARK
      tcol = active ? WHITE : GREY
      # sombra (da profundidad tipo Turbo Vision)
      (1...@h).each do |i|
        CarlOS.at(@top+i+1, @left+@w)
        CarlOS.emit "#{ESC}[48;5;233m  #{RST}"
      end
      CarlOS.at(@top+@h, @left+2)
      CarlOS.emit "#{ESC}[48;5;233m#{" "*@w}#{RST}"
      # marco
      CarlOS.at(@top, @left)
      CarlOS.emit "#{bcol}┌#{"─"*(@w-2)}┐#{RST}"
      (1...@h-1).each do |i|
        CarlOS.at(@top+i, @left)
        CarlOS.emit "#{bcol}│#{RST}#{ESC}[48;5;234m#{" "*(@w-2)}#{RST}#{bcol}│#{RST}"
      end
      CarlOS.at(@top+@h-1, @left)
      CarlOS.emit "#{bcol}└#{"─"*(@w-2)}┘#{RST}"
      # barra de titulo
      CarlOS.at(@top, @left+2)
      tbg = active ? BGRUBY : ""
      CarlOS.emit "#{tbg}#{DARK}[#{tcol} #{@title} #{DARK}]#{RST}"
      # boton cerrar (esquina der)
      CarlOS.at(@top, @left+@w-4)
      CarlOS.emit "#{bcol}[#{tcol}x#{bcol}]#{RST}" if active
      # contenido
      @lines[0, @h-2].each_with_index do |ln, i|
        CarlOS.at(@top+1+i, @left+2)
        clean = ln.gsub(/#{ESC}\[[0-9;]*m/, '')[0, @w-4]
        CarlOS.emit "#{ESC}[48;5;234m#{WHITE}#{clean.ljust(@w-4)}#{RST}"
      end
    end
  end

  # -------- El escritorio --------
  class Desktop
    def initialize
      @rows, @cols = size
      @wins = []
      @next_id = 0
      @active = nil
      @mouse_r = @rows / 2      # posicion del puntero (fila)
      @mouse_c = @cols / 2      # posicion del puntero (col)
      @mouse_on = false         # ¿hay mouse activo?
      @dragging = nil           # ventana que se esta arrastrando
      seed_windows
      start_mouse
    end

    # --- Mouse: leer /dev/input/mice en un thread (consola pura) ---
    def start_mouse
      begin
        @mfh = File.open("/dev/input/mice", "rb")
      rescue StandardError
        @mfh = nil
        return   # sin mouse fisico; el TUI sigue con teclado
      end
      @mouse_on = true
      @mthread = Thread.new do
        loop do
          begin
            pkt = @mfh.read(3)   # protocolo PS/2: 3 bytes
            next unless pkt && pkt.bytesize == 3
            b = pkt.bytes
            btn = b[0]
            dx  = b[1]; dx -= 256 if (btn & 0x10) != 0   # signo X
            dy  = b[2]; dy -= 256 if (btn & 0x20) != 0   # signo Y
            # actualizar posicion (Y invertida: mouse arriba = fila menor)
            @mouse_c = [[@mouse_c + (dx / 3), 1].max, @cols].min
            @mouse_r = [[@mouse_r - (dy / 3), 2].max, @rows].min
            @mouse_left = (btn & 0x01) != 0
            @mouse_event = true
          rescue StandardError
            sleep 0.05
          end
        end
      end
    end

    # --- dibujar el puntero del mouse ---
    def draw_pointer
      return unless @mouse_on
      CarlOS.at(@mouse_r, @mouse_c)
      CarlOS.emit "#{ESC}[38;5;231m#{ESC}[48;5;196m<#{RST}"   # puntero rubi
    end

    # --- accion de clic: activar ventana bajo el puntero / cerrar ---
    def handle_click
      return unless @mouse_left
      # ¿el clic cae sobre alguna ventana? (de arriba hacia abajo)
      @wins.reverse_each do |w|
        if @mouse_r >= w.top && @mouse_r < w.top + w.h &&
           @mouse_c >= w.left && @mouse_c < w.left + w.w
          # ¿clic en la [x] de cerrar?
          if @mouse_r == w.top && @mouse_c >= w.left + w.w - 4
            @wins.delete(w); @active = @wins.last
          else
            @active = w
            @wins.delete(w); @wins << w   # traer al frente
          end
          break
        end
      end
    end

    def size
      r=`stty size 2>/dev/null`.split.map(&:to_i)
      r.length==2 ? r : [24,80]
    end

    def seed_windows
      # una ventana de bienvenida al arrancar
      open_app("Bienvenida")
    end

    APPS = {
      "1" => "Terminal", "2" => "scfetch", "3" => "gpu-probe",
      "4" => "Reloj",    "5" => "Acerca",  "6" => "Bienvenida"
    }

    def app_lines(name)
      case name
      when "Terminal"
        ["Terminal CarlOS (demo)", "", "$ echo hola", "hola", "$ _"]
      when "scfetch"
        out = `scfetch 2>/dev/null`.split("\n")
        out.empty? ? ["(scfetch no disponible)"] : out
      when "gpu-probe"
        out = `sh -c 'ls /dev/dri 2>&1; cat /proc/fb 2>&1' 2>/dev/null`.split("\n")
        ["Diagnostico grafico:", ""] + (out.empty? ? ["(sin datos)"] : out)
      when "Reloj"
        ["", "   #{Time.now.strftime('%H:%M:%S')}", "   #{Time.now.strftime('%A %d/%m/%Y')}", ""]
      when "Acerca"
        ["CarlOS 0.2 Alpha", "Ruby of Sistem", "", "Escritorio TUI con ventanas.", "Ruby puro + ANSI.", "", "SC Co."]
      when "Bienvenida"
        ["Bienvenido a CarlOS 0.2", "", "Teclas:", " 1-6  abrir apps", " TAB  cambiar ventana", " flechas mover", " c    cerrar  ·  q salir"]
      else ["(vacio)"]
      end
    end

    def open_app(name)
      lines = app_lines(name)
      w = [ [lines.map{|l| l.gsub(/#{ESC}\[[0-9;]*m/,'').length}.max || 20, @title_min||24].max + 6, @cols-6 ].min
      h = [lines.length + 3, @rows-6].min
      # posicion escalonada (cascade)
      n = @wins.length
      top = 3 + (n*2) % [@rows-h-3, 1].max
      left = 4 + (n*4) % [@cols-w-4, 1].max
      win = Window.new(@next_id, name, top, left, w, h, lines)
      @next_id += 1
      @wins << win
      @active = win
    end

    def close_active
      return unless @active
      @wins.delete(@active)
      @active = @wins.last
    end

    def cycle_active
      return if @wins.empty?
      i = @wins.index(@active) || -1
      @active = @wins[(i+1) % @wins.length]
      # traer al frente
      @wins.delete(@active); @wins << @active
    end

    def move_active(dr, dc)
      return unless @active
      @active.top = [[@active.top+dr, 2].max, @rows-@active.h-1].min
      @active.left = [[@active.left+dc, 1].max, @cols-@active.w-2].min
    end

    def draw_bar
      CarlOS.at(1,1)
      left = " CarlOS #{RED}◆#{WHITE} Ruby of Sistem  #{DIM}#{@wins.length} ventana(s)"
      clock = Time.now.strftime("%H:%M")
      vis = left.gsub(/#{ESC}\[[0-9;]*m/,'').length
      pad = @cols - vis - clock.length - 2; pad=0 if pad<0
      CarlOS.emit "#{BGBAR}#{WHITE}#{left}#{" "*pad}#{clock} #{RST}"
    end

    def draw_status
      CarlOS.at(@rows,1)
      help = " 1-6 apps · TAB cambia · flechas mueve · c cierra · q sale "
      CarlOS.emit "#{BGBAR}#{DIM}#{help.ljust(@cols)}#{RST}"
    end

    def draw_desktop_bg
      # patron de fondo tenue tipo escritorio
      (2...@rows).each do |r|
        CarlOS.at(r,1)
        print "#{ESC}[48;5;232m#{DIM}#{("·"*@cols)}#{RST}"
      end
    end

    def render
      @first ||= (CarlOS.cls; true)          # cls solo la primera vez
      CarlOS.buf_start                        # empezar a acumular el frame
      render_bg
      render_bar
      @wins.each { |w| w.draw(w.equal?(@active)) }
      render_status
      draw_pointer
      CarlOS.buf_flush                        # volcar TODO de una sola escritura
    end

    # versiones que no re-limpian (el fondo se redibuja encima)
    def render_bg
      (2...@rows).each do |r|
        CarlOS.at(r,1)
        CarlOS.emit "#{ESC}[48;5;232m#{DIM}#{("·"*@cols)}#{RST}"
      end
    end
    def render_bar = draw_bar
    def render_status = draw_status

    def read_key
      c=$stdin.getc
      if c=="\e"
        seq=($stdin.read_nonblock(2) rescue nil)
        return :up if seq=="[A"
        return :down if seq=="[B"
        return :right if seq=="[C"
        return :left if seq=="[D"
        return :esc
      end
      c
    end

    def run
      system("stty raw -echo 2>/dev/null"); CarlOS.hide
      # activar tracking de mouse ANSI tambien (por si corre en terminal X)
      print "#{ESC}[?1000h#{ESC}[?1006h"
      $stdin.sync = true
      loop do
        render
        # esperar tecla O evento de mouse (poll corto)
        ready = IO.select([$stdin], nil, nil, 0.05)
        if @mouse_event
          @mouse_event = false
          handle_click
        end
        next unless ready
        k = read_key
        case k
        when "q","Q" then break
        when "\t" then cycle_active
        when "c","C" then close_active
        when :up then move_active(-1,0)
        when :down then move_active(1,0)
        when :left then move_active(0,-2)
        when :right then move_active(0,2)
        when *APPS.keys then open_app(APPS[k])
        end
      end
    ensure
      print "#{ESC}[?1000l#{ESC}[?1006l"   # desactivar mouse tracking
      @mthread.kill if @mthread
      @mfh.close if @mfh
      system("stty sane 2>/dev/null"); CarlOS.show; CarlOS.cls
      puts "Escritorio CarlOS cerrado."
    end
  end
end

CarlOS::Desktop.new.run if __FILE__ == $PROGRAM_NAME
