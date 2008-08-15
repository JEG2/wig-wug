class Pathfinder
  def initialize
    @map  = nil
    @ruby = nil
    @me   = nil
    
    return "Pathfinder"
  end
  
  def move!(*args)
    update_map(*args)
    pathfind
    p @path
    best_move
  end
  
  private
  
  def update_map(distances, surrounding)
    if @map
      # grow map, if needed
      find_ruby_and_me(distances)
      if @me.first.zero?
        @map.each { |row| row.unshift("O") }
      end
      if @me.first == @map.first.length - 1
        @map.each { |row| row.push("O") }
      end
      if @me.last.zero?
        @map.unshift(Array.new(@map.first.size, "O"))
      end
      if @me.last == @map.length - 1
        @map.pop(Array.new(@map.first.size, "O"))
      end
      find_ruby_and_me(distances)
      
      # update map
      -1.upto(1) do |y_off|
        -1.upto(1) do |x_off|
          next if x_off.zero? and y_off.zero?
          @map[@me.last + y_off][@me.first + x_off] =
            surrounding[y_off + 1][x_off + 1]
        end
      end
    else
      # create map around player
      surrounding[1][1] = "O"
      @map = surrounding
      
      # expand map to Ruby
      dir, x = distances.first < 0 ? [:unshift, 0]: [:push, -1]
      (distances.first.abs - 1).times { @map.each { |row| row.send(dir, "O") } }
      dir, y = distances.last < 0 ? [:push, -1] : [:unshift, 0]
      (distances.last.abs - 1).times do
        @map.send(dir, Array.new(@map.first.size, "O"))
      end
      @map[y][x] = "R"
      
      find_ruby_and_me(distances)
    end
    
    @map.each { |row| puts row.join }
  end
  
  def find_ruby_and_me(distances)
    @ruby = [@map.index(@map.find { |row| row.include?("R") })]
    @ruby.unshift(@map[@ruby.last].index("R"))
    @me   = [@ruby.first - distances.first, @ruby.last + distances.last]
  end
  
  def pathfind
		paths = [[@me]]
		until paths.empty? or paths.first.last == @ruby
			path = paths.shift
			neighbors(*path.last).each do |move|
				next if path.include?(move) or
				        %w[E G].include?(@map[move.last][move.first])
				paths << (path.dup << move)
			end

			paths = paths.sort_by do |trip|
				trip.map { |cell| @map[cell.last][cell.first] == "F" ? 2 : 1 }.
				     inject(0) { |sum, n| sum + n } + distance(trip.last, @ruby)
			end
		end

		@path = if paths.empty?
		        	nil
		        else
		        	paths.shift.values_at(1..-1)
		        end
  end
  
  def best_move
    to = if @path
           @path.first
         else
           neighbors(*@me).find { |x, y| not %[E G].include? @map[y][x] }
         end
    if to
      if @me.first < to.first
        :right
      elsif @me.first > to.first
        :left
      elsif @me.last > to.last
        :up
      else
        :down
      end
    else
      :up
    end
  end
  
  def neighbors(x, y)
    [ [x,     y - 1],
      [x,     y + 1],
      [x - 1, y    ],
      [x + 1, y    ] ].reject { |x, y| x <  0                 or
                                       x >= @map.first.length or
                                       y < 0                  or
                                       y >= @map.length }
  end
  
  def distance(from, to)
		(from.first - to.first).abs + (from.last - to.last).abs
  end
end
