#!/usr/bin/env ruby -wKU

module WigWug
  class Player
    @@colors = %w[ gold      gray     orange  purple    khaki
                   turquoise deeppink fuchsia peachpuff saddlebrown ].
               sort_by { rand }
    
    def initialize(brain_class, x, y)
      @name            = brain_class.new.send(:initialize).to_s || "Unknown"
      @brain           = brain_class.new
      @x               = x
      @y               = y
      @color           = @@colors.shift or raise "Too many players"
      @short_circuited = false
      @lost            = false
    end
    
    attr_reader   :name, :color
    attr_writer   :lost, :short_circuited
    attr_accessor :x, :y
    
    def lost?
      @lost
    end
    
    def short_circuited?
      @short_circuited
    end
    
    def move(*args)
      dir = @brain.move!(*args).to_s.downcase
      raise "Bad direction" unless %w[up down left right].include? dir
      dir
    end
  end
end
