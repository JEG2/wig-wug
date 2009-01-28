# = Wig-Wug
# == Quest for the Treasured Ruby®
#
# Matz has lost the Treasured Ruby!  He has put together Operation Wig-Wug to find it again, and he is
# offering the best Treasured Ruby hunter cold hard cash to help him find it.  The goal of Wig-Wug is
# to beat your opponent's digger to the Treasured Ruby.  You will implement a class much like the Digger
# class below, which will play the game for you.  The goal is to use the information provided by the
# game master to reach the Treasured Ruby in less turns that it takes your opponent.  It is played in
# a grid board, so you will know your coordinates and distances will be measured and presented as coordinate
# pairs.
#
# === Rules for the board
# Here are a few rules of the board for Wig-Wug
#
#   * Boards are arbitrary widths and heights.  They could be 12x12 or 2x320.
#   * There are two types of critters roaming about: fleegols and geegols
#     * Encountering (landng on a space with) a fleegol will cause a short circuit
#       and stop your digger for one turn
#     * Encountering geegols will destroy your digger and end the game
#   * Geegols and fleegols are much like venus fly traps and not able to move
#   * Diggers are always placed equal distances from the Treasured Ruby but may have
#     different configurations of fleegol and geegol placement
#
# === Game flow
#
# Each digger will be given a chance to move one space each turn.
# To move, your digger must return which direction to move from the +move!+
# method.  So for example, to move up, you must return "up" or +:up+.  The
# only valid directions are "up", "down", "left", and "right".
#
# Each time you move, the game master will call +move!+ on your class, passing
# in how far away you are from the Treasured Ruby as a coordinate array as the first argument
# and a matrix of the surrounding spaces as the second argument.  For example,
# if the surrounding spaces looked like this...
#
#   O O F
#   G P O
#   O O O
#   
#   O = open space
#   G = geegol
#   F = fleegol
#   P = player position
#
# ...the game master code will call like this...
#
#   digger.move!([3, 13],
#           [
#             ["O", "O", "F"],
#             ["G", "P", "O"],
#             ["O", "O", "O"],
#           ]
#         )
#
# This signifies there is a fleegol to the NE, a geegol to the west, and you are 3 either
# east or west and 13 north or south of the Treasured Ruby.
#
# * If you are at the game board edge, spaces are indicated by "E".  Touching one of these ends your game.
# * The Treasured Ruby is signified by an "R".  You want to move on to it.
# * You will not be able to see other players on the board, so don't worry!
#
# === A typical game turn
#
# 1. Game master calls move!([0,2], [["O", "O", "O"], ["O", "P", "F"], ["E", "E", "E"]])
# 2. Digger class returns "up"
# 3. Game master calls move!([2,0], [["E", "E", "E"], ["O", "P", "O"], ["O", "O", "G"]]) on opposing digger
# 4. Opposing digger returns "left"
# 5. Game master calls move!([0,1], [["O", "R", "O"], ["O", "P", "O"], ["O", "O", "F"]])
# 6. First digger returns "up"; first digger wins!
#
# Of course, this is a REALLY arbitrary game, but you get the point.
#
#
# == StarDigger by martin.rehfeld@glnetworks.de
#
# StarDigger was announced winner of the Wig-Wug challenge by the Quizmaster at 6th January 2009.
# It uses the A* pathfinding algorithm in a continuous brute force approach being optimistic
# about unknown terrain. The approach is based on research published by Tony Stentz from the
# Robotics Institute at Carnegie Mellon University [aaai96].

class StarDigger

  # provide accessor to digger name -- enable if needed
  # attr_reader :name

  # debug = true will enable printout of known map and projected path after each move!
  def initialize(debug = false)
    @debug = debug
    @player = [0,0]
    @map = DiggerMap.new(@player)
    @name = "Martin Rehfeld's StarDigger"

    # obsolete as return value of initialize gets ignored, but adheres to the
    # interface spec of this competition ;-)
    return @name
  end

  def move!(distance, matrix)
    distance.map! {|c| c.abs } # adjust distance measurement to work with JEG2's Wig-Wug simulator
                               # (it will report negative distances, which I consider a bug)
                               # see http://github.com/JEG2/wig-wug/tree
    @target_position_initialized ||= initialize_target_position(distance)
    update_player_position!

    s = Surrounding.new(matrix)
    determine_treasure_position(s,distance)

    @map.add_surrounding!(@player,s)
    @map.add_treasure!(@target) unless @target.any?{|c| c.fuzzy? }

    puts @map if @debug

    path = @map.path_to(@target)
    raise "No path to target available with matrix = #{matrix.inspect} and known map\n#{@map}" if path.nil?
    move = delta_to_move([path[1][0]-path[0][0], path[1][1]-path[0][1]])

    @last_distance = distance
    @last_move = move

    move.to_s # return chosen move
  end

private

  def initialize_target_position(distance)
    @target ||= (0..1).collect{|i| FuzzyValue.new(@player[i]+distance[i],@player[i]-distance[i]) }
  end

  def update_player_position!
    (0..1).each {|i| @player[i] += move_delta(@last_move)[i] } if @last_move
  end

  def determine_treasure_position(s,distance)
    # seeing the treasure fully discloses its position, doesn't it ;-)
    if s.treasure_visible?
      (0..1).each {|i| @target[i].determine_value(@player[i] + s.treasure[i])}
      return
    end

    # being on the same axis with the treasure discloses one coordinate
    (0..1).each {|i| @target[i].determine_value(@player[i]) if @target[i].fuzzy? && distance[i] == 0 }

    # a visible edge also discloses at least one coordinate of the treasure
    if s.edge_visible?
      @target[0].determine_value(@player[0] + distance[0]) if @target[0].fuzzy? && s.edge_left?
      @target[0].determine_value(@player[0] - distance[0]) if @target[0].fuzzy? && s.edge_right?
      @target[1].determine_value(@player[1] + distance[1]) if @target[1].fuzzy? && s.edge_up?
      @target[1].determine_value(@player[1] - distance[1]) if @target[1].fuzzy? && s.edge_down?
    end

    # once we moved we can determine one coordinate of the treasure by observing the change in distance
    if @last_distance
      direction = DiggerMap.manhattan_distance([0,0],distance) < DiggerMap.manhattan_distance([0,0],@last_distance) ? :towards : :away
      if move_delta(@last_move)[0] != 0
        @target[0].determine_value(@player[0] + distance[0]*move_delta(@last_move)[0]*(direction == :towards ? +1 : -1))
      elsif move_delta(@last_move)[1] != 0
        @target[1].determine_value(@player[1] + distance[1]*move_delta(@last_move)[1]*(direction == :towards ? +1 : -1))
      end
    end
  end

  def move_delta(move)
    { :left  => [-1,  0],
      :right => [+1,  0],
      :up    => [ 0, -1],
      :down  => [ 0, +1] }[move.to_sym]
  end

  def delta_to_move(delta)
    if delta[0] < 0
      :left
    elsif delta[0] > 0
      :right
    elsif delta[1] < 0
      :up
    elsif delta[1] > 0
      :down
    else
      raise "No move available to travel given delta of #{delta.inspect}"
    end
  end

  # A object that can hold multiple values at once, returning a random one
  # of these when used
  class FuzzyValue
    def initialize(*values)
      @values = Array(values).uniq
    end

    def determine_value(value)
      @values = [value]
    end

    def fuzzy?
      @values.size > 1
    end

    # delegate anything else to a random member of @values
    undef to_s # to_s shall also be called on delegate object
    def method_missing(key, *args)
      @values[rand(@values.size)].send key, *args
    end
  end

  # the immediate surrounding of the digger
  class Surrounding

    def initialize(matrix)
      @matrix = matrix
    end

    def treasure_visible?
      @matrix.flatten.any?{|cell| cell.to_sym == :R }
    end

    def treasure
      [treasure_x, treasure_y]
    end

    def edge_visible?
      @matrix.flatten.any?{|cell| cell.to_sym == :E }
    end

    def edge_left?
      @matrix[1][0].to_sym == :E
    end

    def edge_right?
      @matrix[1][2].to_sym == :E
    end

    def edge_up?
      @matrix[0][1].to_sym == :E
    end

    def edge_down?
      @matrix[2][1].to_sym == :E
    end

    def covered_positions
      positions = []
      @matrix.each_with_index do |line,y|
        line.each_with_index do |cell,x|
          positions << [x-1,y-1]
        end
      end
      positions
    end

    def terrain(delta)
      @matrix[delta[1]+1][delta[0]+1]
    end

  private

    def treasure_x
      @matrix.each do |line|
        line.each_with_index do |cell,index|
          return index-1 if cell.to_sym == :R
        end
      end
      nil
    end

    def treasure_y
      @matrix.each_with_index do |line,index|
        return index-1 if line.any?{|cell| cell.to_sym == :R }
      end
      nil
    end
  end

  # A* pathfinding algorithm
  # courtesy of http://branch14.org/snippets/a_star_in_ruby.html
  class AStar

    def initialize(adjacency_func, cost_func, distance_func)
      @adjacency = adjacency_func
      @cost      = cost_func
      @distance  = distance_func
    end

    def find_path(start, goal)
      been_there = {}
      pqueue = PriorityQueue.new
      pqueue << [1, [start, [], 0]]

      while !pqueue.empty?
        spot, path_so_far, cost_so_far = pqueue.next
        next if been_there[spot]

        newpath = path_so_far + [spot]
        return newpath if (spot == goal)

        been_there[spot] = 1

        @adjacency.call(spot).each do |newspot|
          next if been_there[newspot]

          tcost = @cost.call(spot, newspot)
          next unless tcost
          newcost = cost_so_far + tcost
          pqueue << [newcost + @distance.call(goal, newspot),
                     [newspot, newpath, newcost]]
        end
      end

      return nil
    end

    # a simple priority queue used internally by A*
    class PriorityQueue
      def initialize
        @list = []
      end

      def add(priority, item)
        @list << [priority, @list.length, item]
        @list.sort!
        self
      end

      def <<(pritem)
        add(*pritem)
      end

      def next
        @list.shift[2]
      end

      def empty?
        @list.empty?
      end
    end

  end

  # the map of the currently known "world", also encapsulates routing to target
  class DiggerMap

    attr_reader :treasure_position

    def initialize(origin)
      @current_player_position = origin
      @player_path = [] << @current_player_position
      @map = {}
    end

    def add_surrounding!(player_pos,s)
      @current_player_position = player_pos.dup
      @player_path << @current_player_position
      s.covered_positions.each do |delta|
        position = [player_pos[0]+delta[0],player_pos[1]+delta[1]]
        @map[position] ||= {}
        @map[position][:terrain] = s.terrain(delta).to_sym if @map[position][:terrain] == :P || @map[position][:terrain].nil?
      end
    end

    def add_treasure!(treasure_pos)
      @treasure_position = treasure_pos.collect{|c| c.to_i }
      @map[@treasure_position] ||= {}
      @map[@treasure_position][:terrain] = :R
    end

    def self.manhattan_distance(p1,p2)
      distance(p1,p2).inject(0){|sum,coord| sum + coord.abs}
    end

    def path_to(goal)
      return nil unless @current_player_position

      a_star = AStar.new(
        # adjacency function
        Proc.new {|position| DiggerMap.adjacent_positions(position) },
        # cost function (be optimistic about unknown terrain)
        Proc.new {|old_position, position| terrain_cost_at(position) },
        # distance function
        Proc.new {|target, position| DiggerMap.manhattan_distance(position,target) }
      )

      @further_path = a_star.find_path(@current_player_position, goal.map{|c| c.to_i})
    end

    def to_s
      x_coordinates = known_positions.collect{|position| position[0]}
      y_coordinates = known_positions.collect{|position| position[1]}
      (y_coordinates.min..y_coordinates.max).each do |y|
        (x_coordinates.min..x_coordinates.max).each do |x|
          print_cell [x,y]
        end
        print "\n"
      end
    end

  private

    def self.distance(p1, p2)
      [p2[0]-p1[0], p2[1]-p1[1]]
    end

    def self.adjacent_positions(position)
      [[-1,0], [1,0], [0,-1], [0,1]].collect{|delta| [position[0]+delta[0],position[1]+delta[1]] }
    end

    def self.terrain_cost(terrain)
      case terrain.to_sym
        when :O then 1
        when :F then 2
        when :R then 1
        else nil # non-walkable!
      end
    end

    def terrain_cost_at(position)
      DiggerMap.terrain_cost((@map[position] || {:terrain => :O})[:terrain])
    end

    def on_player_path?(position)
      @player_path.include? position
    end

    def on_further_path?(position)
      @further_path.include? position rescue false
    end

    def known_positions
      @map.keys
    end

    def red(&block)
      print "\e[31m"
      yield if block
      print "\e[0m"
    end

    def green(&block)
      print "\e[32m"
      yield if block
      print "\e[0m"
    end

    def cell_symbol(position)
      cell = @map[position]
      if    cell                       then position == @player_path.first ? '@' : cell[:terrain] || "?"
      elsif on_further_path?(position) then "."
      else                                  " " end
    end

    def print_cell(position)
      if    on_player_path?(position)  then green { print cell_symbol(position) }
      elsif on_further_path?(position) then red   { print cell_symbol(position) }
      else                                  print cell_symbol(position) end
    end
  end

end