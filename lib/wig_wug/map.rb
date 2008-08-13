#!/usr/bin/env ruby -wKU

require File.join(File.dirname(__FILE__), "player")
require File.join(File.dirname(__FILE__), *%w[.. .. vendor svg])

module WigWug
  class Map
    def self.generate(details = Hash.new)
      # build a board
      limit  = details[:size_limit] || 500
      width  = details[:width]      || rand(limit) + 1
      height = details[:height]     || rand(limit) + 1
      board  = Array.new(height) { Array.new(width, "O") }
    
      # place geegols and fleegols
      f_chance = details[:fleegols] || 20
      g_chance = details[:geegols]  || 10
      board.each_index do |y|
        board[y].each_index do |x|
          chance = rand(100)
          if chance < f_chance
            board[y][x] = "F"
          elsif chance < f_chance + g_chance
            board[y][x] = "G"
          end
        end
      end
    
      # place the ruby
      board[rand(board.size)][rand(board.first.size)] = "R"
      
      # place players
      players = Array.new
      Array(details[:brains]).each do |brain|
        loop do
          x = rand(board.first.size)
          y = rand(board.size)
          if board[y][x] == "O"
            players << Player.new(brain, x, y)
            break
          end
        end
      end
    
      new(board, players)
    end
    
    def self.from_file(path, *brains)
      brains = brains.flatten # support passing an Array
      
      # load board
      board = File.open(path) do |map|
        map.inject(Array.new) do |rows, line|
          line.tr!("#{brains.size}-9", "O") if brains.size < 10
          rows + [line.upcase.delete("^ORFG0-9").split("")]
        end
      end
      
      # check board
      raise "Empty board" if board.empty?
      raise "Uneven board widths" \
        unless board.all? { |row| row.size == board.first.size }
      raise "Must have exactly one ruby" \
        unless board.flatten.select { |cell| cell == "R" }.size == 1
      
      # setup players
      players = (0...brains.size).map do |i|
        y = board.index(board.find { |row| row.include? i.to_s }) or
            raise "Map doesn't support enough players"
        x = board[y].index(i.to_s)
        board[y][x] = "O"
        Player.new(brains[i], x, y)
      end
      
      new(board, players)
    end
  
    def initialize(board, players)
      @board   = board
      @players = players
    
      @width  = @board.first.size
      @height = @board.size
      @ruby_y = @board.index(@board.find { |row| row.include? "R" })
      @ruby_x = @board[@ruby_y].index("R")
    end
    private_class_method :new
  
    attr_reader :width, :height, :ruby_x, :ruby_y, :players
  
    def [](x, y)
      @board[y][x]
    end
  
    def each_with_xy
      @board.each_index do |y|
        @board[y].each_index do |x|
          yield self[x, y], x, y
        end
      end
    end
  
    def to_svg(options = Hash.new)
      scale  = options[:scale] || 10
      center = scale  / 2.0
      max_x  = width  * scale
      max_y  = height * scale
      bottom = max_y + (options[:legend] ? players.size * 15 + 5 : 0)
    
      SVG::Image.new(max_x, bottom) do |svg|
        # background
        svg.rect(0, 0, max_x, bottom, :fill => :black)
        # grid
        if options[:grid]
          (0..max_x).step(scale) do |x|
            svg.line(x, 0, x, max_y, :stroke => :white)
          end
          (0..max_y).step(scale) do |y|
            svg.line(0, y, max_x, y, :stroke => :white)
          end
        end
        
        # legend
        if options[:legend]
          players.each_with_index do |player, i|
            down = max_y + i * 15 + 5
            svg.circle( center, down + [6, center].max, center,
                        :fill => player.color )
            svg.text( player.name, scale + 5, down + 12,
                      :font_family => "Verdana",
                      :font_size   => 12,
                      :fill        => :white )
          end
        end

        each_with_xy do |cell, x, y|
          case cell
          when "R" # ruby
            svg.rect(x * scale, y * scale, scale, scale, :fill => :red)
          when "F" # fleegol
            svg.rect(x * scale, y * scale, scale, scale, :fill => :blue)
          when "G" # geegol
            svg.rect(x * scale, y * scale, scale, scale, :fill => :green)
          end

          # players
          if here = players.find { |player| not player.lost? and
                                            player.x == x    and
                                            player.y == y }
            svg.circle( x * scale + center, y * scale + center, center,
                        :fill => here.color )
          end
        end
      end
    end
  end
end
