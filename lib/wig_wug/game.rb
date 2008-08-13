#!/usr/bin/env ruby -wKU

module WigWug
  class Game
    def initialize(map, options = Hash.new)
      @map     = map
      @turn    = 0
      @text    = options[:text]
      @svg     = options[:svg]
      @options = options
      
      @map.each_with_xy do |cell, x, _|
        print cell
        puts if x == @map.width - 1
      end
      @map.players.each do |player|
        print_text("#{player.name}:  Starts at x=#{player.x}, y=#{player.y}.")
      end
      print_text
      draw_svg
    end
    
    def do_turn
      @turn += 1
      print_text("Turn #{@turn}")
      
      @map.players.each do |player|
        next if player.lost?
        
        # skip player's turn, if needed
        if player.short_circuited?
          player.short_circuited = false
          print_text("#{player.name}:  Loses a turn.")
          next
        end
        
        # find player's move
        distance    = [@map.ruby_x - player.x, @map.ruby_y - player.y]
        surrounding = Array.new(3) { Array.new(3, nil) }
        surrounding[1][1] = "P"
        -1.upto(1) do |y_off|
          -1.upto(1) do |x_off|
            next if x_off.zero? and y_off.zero?
            x = player.x + x_off
            y = player.y + y_off
            if x.between?(0, @map.width) and y.between?(0, @map.height)
              surrounding[y_off + 1][x_off + 1] = @map[x, y]
            else
              surrounding[y_off + 1][x_off + 1] = "E"
            end
          end
        end
        direction = player.move( distance,
                                 Marshal.load(Marshal.dump(surrounding)) )
        offsets   = case direction
                    when "up"    then [ 0, -1]
                    when "down"  then [ 0,  1]
                    when "left"  then [-1,  0]
                    when "right" then [ 1,  0]
                    end
        
        # move player
        cell = surrounding[offsets.last + 1][offsets.first + 1]
        if %w[E G].include? cell
          player.lost = true
          print_text( "#{player.name}:  Stepped " +
                      (cell == "E" ? "off the edge" : "on a geeol.") )
        else
          player.x += offsets.first
          player.y += offsets.last
          if @map[player.x, player.y] == "R"
            print_text("#{player.name}:  (#{direction}) Reached the ruby.")
            return player  # winner
          elsif @map[player.x, player.y] == "F"
            player.short_circuited = true
            print_text("#{player.name}:  (#{direction}) Stepped on a fleegol.")
          else
            print_text( "#{player.name}:  Moves #{direction} to " +
                        "x=#{player.x}, y=#{player.y}." )
          end
        end
      end
      
      if @map.players.all? { |player| player.lost? }
        true  # game over with no winner
      else
        false  # no winner yet
      end
    ensure  # after every turn, no matter how it ends
      print_text
      draw_svg
    end
    
    def run(delay = 0, limit = nil)
      loop do
        winner = do_turn
        break winner if winner or (limit and @turn == limit)
        sleep delay
      end
    end
    
    private
    
    def print_text(message = "")
      return unless @text
      puts message
    end
    
    def draw_svg
      return unless @svg
      File.open(File.join(@svg, "turn_#{@turn}.svg"), "w") do |svg|
        svg << @map.to_svg(@options)
      end
    end
  end
end
