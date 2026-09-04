#!/usr/bin/env ruby
# frozen_string_literal: true
#==========================================================
#  carlos-tui.rb — Entorno de escritorio TUI de CarlOS
#  "Ruby of Sistem" — modo grafico de segunda (sin X).
#
#  Corre sobre la consola de texto. Ruby puro + ANSI, cero
#  dependencias. Barra superior, menu de apps, y ventanas.
#==========================================================

module CarlOS
  # --- ANSI helpers ---
  ESC = "\e"
  def self.cls   = print "#{ESC}[2J#{ESC}[H"
  def self.at(r,c) = print "#{ESC}[#{r};#{c}H"
  def self.hide  = print "#{ESC}[?25l"
  def self.show  = print "#{ESC}[?25h"
  def self.reset = print "#{ESC}[0m"

  # colores (paleta rubi CarlOS)
  RED   = "#{ESC}[38;5;196m"
  DARK  = "#{ESC}[38;5;88m"
  LIGHT = "#{ESC}[38;5;217m"
  WHITE = "#{ESC}[97m"
  DIM   = "#{ESC}[38;5;240m"
  BGRUBY = "#{ESC}[48;5;88m"
  BGBAR  = "#{ESC}[48;5;236m"
  RST   = "#{ESC}[0m"

  class TUI
    def initialize
      @rows, @cols = term_size
      @apps = [
        ["Terminal",   "abrir shell"],
        ["Editor",     "editar archivos"],
        ["gpu-probe",  "diagnostico grafico"],
        ["scfetch",    "info del sistema"],
        ["Ajustes",    "configuracion"],
        ["Acerca de",  "CarlOS 0.2 Ruby"],
        ["Salir",      "cerrar TUI"]
      ]
      @sel = 0
    end

    def term_size
      r = `stty size 2>/dev/null`.split.map(&:to_i)
      r.length == 2 ? r : [24, 80]
    end

    # --- dibujar la barra superior ---
    def draw_bar
      CarlOS.at(1,1)
      bar = " CarlOS #{RED}◆#{WHITE} Ruby of Sistem"
      clock = Time.now.strftime("%H:%M  %d/%m")
      pad = @cols - visible_len(bar) - clock.length - 2
      pad = 0 if pad < 0
      print "#{BGBAR}#{WHITE}#{bar}#{" " * pad}#{clock} #{RST}"
    end

    def visible_len(s)
      s.gsub(/\e\[[0-9;]*m/, '').length
    end

    # --- caja con borde ---
    def box(top, left, h, w, title = nil)
      CarlOS.at(top, left)
      print "#{RED}┌#{"─" * (w-2)}┐#{RST}"
      (1...h-1).each do |i|
        CarlOS.at(top+i, left)
        print "#{RED}│#{RST}#{" " * (w-2)}#{RED}│#{RST}"
      end
      CarlOS.at(top+h-1, left)
      print "#{RED}└#{"─" * (w-2)}┘#{RST}"
      if title
        CarlOS.at(top, left+2)
        print "#{DARK}[#{WHITE} #{title} #{DARK}]#{RST}"
      end
    end

    # --- el menu de apps ---
    def draw_menu
      mtop = 4; mleft = 4; mw = 34
      box(mtop, mleft, @apps.length + 4, mw, "Aplicaciones")
      @apps.each_with_index do |(name, desc), i|
        CarlOS.at(mtop + 2 + i, mleft + 2)
        if i == @sel
          print "#{BGRUBY}#{WHITE} ▶ #{name.ljust(12)} #{DIM}#{desc.ljust(mw-20)}#{RST}"
        else
          print "#{WHITE}   #{name.ljust(12)} #{DIM}#{desc}#{RST}"
        end
      end
    end

    # --- panel derecho: logo + info ---
    def draw_panel
      ptop = 4; pleft = 42; pw = @cols - pleft - 2
      pw = 30 if pw < 30
      box(ptop, pleft, @apps.length + 4, pw, "CarlOS")
      # mini gema rubi
      gem = ["  *** ==", " *****###", "###***##", "  ##==##", "   ##=*"]
      gem.each_with_index do |line, i|
        CarlOS.at(ptop + 2 + i, pleft + 3)
        colored = line.chars.map { |c|
          case c
          when '*' then "#{RED}*"
          when '#' then "#{DARK}#"
          when '=' then "#{LIGHT}="
          else " "
          end
        }.join
        print "#{colored}#{RST}"
      end
      CarlOS.at(ptop + 8, pleft + 3)
      print "#{WHITE}CarlOS 0.2 Alpha#{RST}"
      CarlOS.at(ptop + 9, pleft + 3)
      print "#{DIM}Ruby of Sistem#{RST}"
    end

    # --- barra de estado inferior ---
    def draw_status
      CarlOS.at(@rows, 1)
      help = " ↑/↓ mover  ·  ENTER abrir  ·  q salir "
      print "#{BGBAR}#{DIM}#{help.ljust(@cols)}#{RST}"
    end

    def render
      CarlOS.cls
      draw_bar
      draw_menu
      draw_panel
      draw_status
      $stdout.flush
    end

    # --- leer una tecla (incluye flechas) ---
    def read_key
      c = $stdin.getc
      if c == "\e"
        c2 = $stdin.read_nonblock(2) rescue nil
        return :up   if c2 == "[A"
        return :down if c2 == "[B"
        return :esc
      end
      case c
      when "\r", "\n" then :enter
      when "q", "Q"   then :quit
      when "j"        then :down
      when "k"        then :up
      else c
      end
    end

    def run_app(name)
      CarlOS.cls; CarlOS.show
      system("stty sane")
      case name
      when "Terminal" then system(ENV["SHELL"] || "/bin/sh")
      when "scfetch"  then system("scfetch"); pausa
      when "gpu-probe" then system("gpu-probe"); pausa
      when "Acerca de" then acerca; pausa
      when "Salir"    then return :exit
      else
        puts "\n  '#{name}' aun no implementado.\n"; pausa
      end
      raw_mode
      :ok
    end

    def acerca
      puts
      puts "  CarlOS 0.2 Alpha \"Ruby of Sistem\""
      puts "  Entorno TUI — modo grafico de segunda"
      puts "  Escrito en Ruby puro sobre ANSI."
      puts
      puts "  Cuando el DRM/Xorg funcione, el entorno"
      puts "  grafico completo toma el relevo."
      puts
    end

    def pausa
      print "\n  [ ENTER para volver ] "
      $stdin.gets
    end

    def raw_mode
      system("stty raw -echo 2>/dev/null")
      CarlOS.hide
    end

    def run
      raw_mode
      loop do
        render
        case read_key
        when :up    then @sel = (@sel - 1) % @apps.length
        when :down  then @sel = (@sel + 1) % @apps.length
        when :quit, :esc then break
        when :enter
          break if run_app(@apps[@sel][0]) == :exit
        end
      end
    ensure
      system("stty sane 2>/dev/null")
      CarlOS.show; CarlOS.reset; CarlOS.cls
      puts "Saliste del entorno TUI de CarlOS."
    end
  end
end

CarlOS::TUI.new.run if __FILE__ == $PROGRAM_NAME
