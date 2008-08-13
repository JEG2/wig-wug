#!/usr/bin/env ruby -wKU

module WigWug
  VERSION = "0.0.1"
  
  LIB_DIR = File.join(File.dirname(__FILE__), "wig_wug")
end

require File.join(WigWug::LIB_DIR, "map")
require File.join(WigWug::LIB_DIR, "game")
