#!/usr/bin/env ruby
# frozen_string_literal: true
#==========================================================
#  carlos-tetris.rb — Tetris estilo EGT de CarlOS
#  "moskau" — con la estetica rubi del escritorio.
#  Ruby puro + ANSI. Musica opcional (buzzer/beep) aparte.
#
#  Controles:
#    ← →   mover      ↑ / x   rotar
#    ↓     bajar      espacio caida rapida
#    p     pausa      q       salir
#==========================================================

module CarlOS
  ESC = "\e"
  def self.cls   = print("#{ESC}[2J#{ESC}[H")
  def self.at(r,c) = print("#{ESC}[#{r};#{c}H")
  def self.hide  = print("#{ESC}[?25l")
  def self.show  = print("#{ESC}[?25h")

  RED="#{ESC}[38;5;196m"; DARK="#{ESC}[38;5;88m"; LIGHT="#{ESC}[38;5;217m"
  WHITE="#{ESC}[97m"; DIM="#{ESC}[38;5;240m"
  BGBAR="#{ESC}[48;5;236m"; RST="#{ESC}[0m"

  # Colores de las 7 piezas (256-color)
  PCOL = {
    'I' => "#{ESC}[38;5;51m",   # cyan
    'O' => "#{ESC}[38;5;226m",  # amarillo
    'T' => "#{ESC}[38;5;201m",  # magenta
    'S' => "#{ESC}[38;5;46m",   # verde
    'Z' => "#{ESC}[38;5;196m",  # rojo (rubi)
    'J' => "#{ESC}[38;5;21m",   # azul
    'L' => "#{ESC}[38;5;208m"   # naranja
  }

  # Formas (rotaciones base) — cada pieza como lista de [fila,col]
  SHAPES = {
    'I' => [[0,0],[0,1],[0,2],[0,3]],
    'O' => [[0,0],[0,1],[1,0],[1,1]],
    'T' => [[0,0],[0,1],[0,2],[1,1]],
    'S' => [[0,1],[0,2],[1,0],[1,1]],
    'Z' => [[0,0],[0,1],[1,1],[1,2]],
    'J' => [[0,0],[1,0],[1,1],[1,2]],
    'L' => [[0,2],[1,0],[1,1],[1,2]]
  }

  class Tetris
    W = 10   # ancho del tablero (celdas)
    H = 18   # alto

    def initialize(mono: false, vol: 4)
      @board = Array.new(H) { Array.new(W, nil) }
      @score = 0; @lines = 0; @level = 1
      @over = false; @paused = false
      @mono_only = mono      # -m: solo melodia mono, sin poli/burla
      @vol = vol             # -v: nivel de volumen 1-4
      spawn
    end

    def spawn
      @type = SHAPES.keys.sample
      @cells = SHAPES[@type].map(&:dup)
      @pr = 0; @pc = 3   # posicion (fila, col) del origen
      @over = true if collide?(@cells, @pr, @pc)
    end

    def collide?(cells, pr, pc)
      cells.any? do |dr, dc|
        r = pr + dr; c = pc + dc
        c < 0 || c >= W || r >= H || (r >= 0 && @board[r][c])
      end
    end

    def rotate
      # rotar 90°: [r,c] -> [c, -r], luego normalizar
      rc = @cells.map { |dr, dc| [dc, -dr] }
      minr = rc.map { |r, _| r }.min
      minc = rc.map { |_, c| c }.min
      rc = rc.map { |r, c| [r - minr, c - minc] }
      @cells = rc unless collide?(rc, @pr, @pc)
    end

    def move(dr, dc)
      if collide?(@cells, @pr + dr, @pc + dc)
        if dr > 0   # tocó fondo al bajar
          lock
        end
        return false
      end
      @pr += dr; @pc += dc
      true
    end

    def drop
      move(1, 0) while !collide?(@cells, @pr + 1, @pc)
      lock
    end

    def lock
      @cells.each do |dr, dc|
        r = @pr + dr; c = @pc + dc
        @board[r][c] = @type if r >= 0
      end
      clear_lines
      spawn
    end

    def clear_lines
      full = (0...H).select { |r| @board[r].all? }
      return if full.empty?
      full.each { |r| @board.delete_at(r); @board.unshift(Array.new(W, nil)) }
      n = full.length
      @lines += n
      @score += [0, 100, 300, 500, 800][n] * @level
      @level = 1 + @lines / 10
    end

    def tick_delay = [0.5 - (@level - 1) * 0.04, 0.08].max


    # --- musica reactiva: que tan "mal" va el jugador (0=bien, alto=mal) ---
    def indice_burla
      # altura de la pila (fila mas alta con bloque)
      altura = 0
      (0...H).each do |r|
        if @board[r].any?
          altura = H - r
          break
        end
      end
      # huecos: celda vacia con algun bloque encima en su columna
      huecos = 0
      (0...W).each do |c|
        visto = false
        (0...H).each do |r|
          if @board[r][c]
            visto = true
          elsif visto
            huecos += 1
          end
        end
      end
      # indice combinado
      altura + huecos * 2
    end

    # escribe el nivel de burla (0-10) en vivo; burlaplay lo lee y modula
    def actualizar_musica
      return if @mono_only     # -m: sin burla, la musica no escala
      idx = indice_burla
      nivel = idx / 4
      nivel = 10 if nivel > 10
      nivel = 0 if nivel < 0
      begin
        File.write("/tmp/burla.level", nivel.to_s)
      rescue StandardError
        nil
      end
    end

    # ---- dibujo estilo EGT ----
    def draw
      buf = +"#{ESC}[H"
      # barra superior
      buf << "#{BGBAR}#{WHITE} CarlOS #{RED}◆#{WHITE} moskau :: Tetris"
      buf << "#{" " * 40}#{RST}\r\n"
      # marco del tablero
      top = 2; left = 4
      bw = W * 2 + 2
      buf << draw_at(top, left, "#{RED}┌#{"─" * (bw-2)}┐#{RST}")
      (0...H).each do |r|
        line = +"#{RED}│#{RST}"
        (0...W).each do |c|
          cell = @board[r][c]
          # ¿pieza actual aquí?
          active = @cells.any? { |dr, dc| @pr+dr == r && @pc+dc == c }
          if active
            line << "#{PCOL[@type]}██#{RST}"
          elsif cell
            line << "#{PCOL[cell]}██#{RST}"
          else
            line << "#{DIM}·#{RST} "
          end
        end
        line << "#{RED}│#{RST}"
        buf << draw_at(top + 1 + r, left, line)
      end
      buf << draw_at(top + 1 + H, left, "#{RED}└#{"─" * (bw-2)}┘#{RST}")

      # panel de info a la derecha
      pl = left + bw + 3
      buf << draw_at(top+1, pl, "#{RED}┌ #{WHITE}INFO #{RED}────────┐#{RST}")
      buf << draw_at(top+2, pl, "#{RED}│#{WHITE} Puntos:        #{RED}│#{RST}")
      buf << draw_at(top+3, pl, "#{RED}│#{LIGHT} #{@score.to_s.ljust(14)}#{RED}│#{RST}")
      buf << draw_at(top+4, pl, "#{RED}│#{WHITE} Lineas: #{@lines.to_s.ljust(7)}#{RED}│#{RST}")
      buf << draw_at(top+5, pl, "#{RED}│#{WHITE} Nivel:  #{@level.to_s.ljust(7)}#{RED}│#{RST}")
      buf << draw_at(top+6, pl, "#{RED}└───────────────┘#{RST}")
      buf << draw_at(top+8, pl, "#{DIM}← → mover#{RST}")
      buf << draw_at(top+9, pl, "#{DIM}↑/x rotar#{RST}")
      buf << draw_at(top+10, pl, "#{DIM}↓ bajar  espacio caer#{RST}")
      buf << draw_at(top+11, pl, "#{DIM}p pausa  q salir#{RST}")

      if @paused
        buf << draw_at(top + H/2, left + 3, "#{BGBAR}#{WHITE} PAUSA #{RST}")
      end
      print buf
      $stdout.flush
    end

    def draw_at(r, c, s) = "#{ESC}[#{r};#{c}H#{s}"

    def game_over_screen
      CarlOS.at(9, 8)
      print "#{RED}╔══════════════════╗#{RST}"
      CarlOS.at(10, 8); print "#{RED}║#{WHITE}   GAME  OVER     #{RED}║#{RST}"
      CarlOS.at(11, 8); print "#{RED}║#{WHITE}  Puntos: #{@score.to_s.ljust(7)} #{RED}║#{RST}"
      CarlOS.at(12, 8); print "#{RED}╚══════════════════╝#{RST}"
      CarlOS.at(14, 8); print "#{DIM}ENTER para salir#{RST}"
      $stdout.flush
      loop { break if [nil,"\r","\n","q"].include?($stdin.getc) }
    end

    def read_key_nonblock
      r = IO.select([$stdin], nil, nil, tick_delay)
      return nil unless r
      c = $stdin.getc
      if c == "\e"
        seq = ($stdin.read_nonblock(2) rescue "")
        return :left if seq == "[D"
        return :right if seq == "[C"
        return :up if seq == "[A"
        return :down if seq == "[B"
        return :esc
      end
      c
    end

    def run
      system("stty raw -echo 2>/dev/null"); CarlOS.hide; CarlOS.cls
      if @mono_only
        # -m: melodia mono limpia en loop, con volumen -v
        system("sh -c 'while :; do tuneplay /opt/carlos/sound/N1.tones #{@vol}; done' >/dev/null 2>&1 &") rescue nil
      else
        File.write("/tmp/burla.level", "0") rescue nil
        system("burlaplay /opt/carlos/sound/POLY.tones --file /tmp/burla.level >/dev/null 2>&1 &") rescue nil
      end
      last = Time.now
      until @over
        draw
        k = read_key_nonblock
        case k
        when :left then move(0,-1)
        when :right then move(0,1)
        when :down then move(1,0)
        when :up, "x", "X" then rotate
        when " " then drop
        when "p","P" then @paused = !@paused
        when "q","Q","\e" then break
        end
        if !@paused && Time.now - last >= tick_delay
          move(1,0); last = Time.now
          actualizar_musica
        end
      end
      game_over_screen if @over
    ensure
      system("pkill burlaplay >/dev/null 2>&1") rescue nil
      system("pkill tuneplay >/dev/null 2>&1") rescue nil
      system("buzzeroff >/dev/null 2>&1") rescue nil
      system("stty sane 2>/dev/null"); CarlOS.show; CarlOS.cls
      puts "Gracias por jugar CarlOS Tetris (moskau)."
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  mono = ARGV.include?("-m")
  # -v baja volumen: -v=3(medio) -vv=2(bajo) -vvv=1(susurro); sin -v = 4(full)
  vcount = ARGV.count { |a| a =~ /\A-v+\z/ ? nil : false } # placeholder
  vflags = ARGV.select { |a| a =~ /\A-v+\z/ }
  vol = 4
  unless vflags.empty?
    vs = vflags.map { |f| f.count("v") }.max
    vol = [4 - vs, 1].max     # -v->3, -vv->2, -vvv->1
  end
  CarlOS::Tetris.new(mono: mono, vol: vol).run
end
