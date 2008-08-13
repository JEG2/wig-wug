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
class NaiveDigger
  def initialize
    @previous_x = 0
    @previous_y = 0
    @previous_x_move = "left"
    @previous_y_move = "right"

    # This will be used as the digger's name and be displayed in the results
    return "Me-So-Stupid"
  end
  
  def move!(distance, matrix)
    if distance[0] > 0
      if distance[0] > @previous_x
        @previous_x_move = @previous_x_move == "left" ? "right" : "left"
      else 
        return @previous_x_move
      end      
    else
      if distance[1] > @previous_y
        @previous_y_move = @previous_y_move == "up" ? "down" : "up"
      else 
        return @previous_y_move
      end
    end
  end
end
