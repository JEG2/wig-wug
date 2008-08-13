#!/usr/bin/env ruby -wKU

require 'enumerator'
require 'forwardable'

module SVG
  class Shape
    XML_ESCAPES = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;'}
    
    def initialize(name, attrs = { })
      @name  = String(name)
      @attrs = attrs.inject({ }) do |h, (k, v)|
        h.merge(String(k).tr('_', '-') => v)
      end
    end
    
    attr_accessor :name
    attr_reader   :attrs
    
    def empty?
      not (@attrs['title'] or @attrs['desc'])
    end
    
    def write(io_or_str, indent = '')
      io_or_str << "#{indent}<#{@name} #{xml_attrs}"
      if empty? and @name != 'svg'
        io_or_str << %Q{/>\n}
      else
        io_or_str << ">\n"
        %w[title desc].each do |f|
          io_or_str << "#{indent + '  '}<#{f}>#{xml_safe @attrs[f]}</#{f}>\n" \
            if @attrs[f]
        end
        yield io_or_str if block_given?
        io_or_str << "#{indent}</#{@name}>\n"
      end
    end

    def to_s
      str = ''
      write(str)
      str
    end
    
    private
    
    def xml_attrs
      @attrs.inject('') do |str, (k, v)|
        next str if %w[title desc].include? k
        %Q{#{str} #{k}="} +
        ( k == 'points'                                                      ?
            Array(v).flatten.enum_slice(2).map { |p| p.join(',') }.join(' ') :
            String(v) )   +
        '"'
      end.lstrip
    end
    
    def xml_safe(text)
      String(text).gsub(/[#{Regexp.escape(XML_ESCAPES.keys.join)}]/) do |e|
        XML_ESCAPES[e]
      end
    end
  end
  
  class Text < Shape
    def initialize(contents, attrs = { })
      super(:text, attrs)
      @contents = contents
    end
    
    def empty?
      false
    end
    
    def write(io_or_str, indent = '')
      super(io_or_str, indent) do |i_or_s|
        i_or_s << "#{indent + '  '}#{xml_safe(@contents)}"
        i_or_s << "\n" unless @contents[-1] == ?\n
      end
    end
  end
  
  class Group < Shape
    extend  Forwardable
    include Enumerable
    
    def initialize(attrs = { })
      super(:g, attrs)
      @contents = [ ]
    end
    
    def_delegators :@contents, :empty?, :[], :[]=, :clear, :delete_at, :size
    
    def each(nested = true, &iterator)
      if iterator
        @contents.each do |shape|
          iterator[shape]
          shape.each(&iterator) if nested and shape.respond_to? :each
        end
      else
        enum_for(:each, nested)
      end
    end
    
    def rect(x, y, width, height, *args)
      attrs = (args.last.is_a?(Hash) ? args.pop : { }).merge(
        :x      => x,
        :y      => y,
        :width  => width,
        :height => height
      )
      %w[rx ry].zip(args) { |k, v| attrs.update(k => v) if v }
      @contents << Shape.new(:rect, attrs)
    end
    alias_method :rounded_rect, :rect
    
    def circle(cx, cy, r, attrs = { })
      @contents << Shape.new( :circle,
                              attrs.merge(:cx => cx, :cy => cy, :r => r) )
    end
    
    def ellipse(cx, cy, rx, ry, attrs = { })
      @contents << Shape.new( :ellipse, attrs.merge( :cx => cx,
                                                     :cy => cy,
                                                     :rx => rx,
                                                     :ry => ry ) )
    end
    
    def line(x1, y1, x2, y2, attrs = { })
      @contents << Shape.new( :line, attrs.merge( :x1 => x1,
                                                  :y1 => y1,
                                                  :x2 => x2,
                                                  :y2 => y2 ) )
    end
    
    def point(x, y, attrs = { })
      line(x, y, x, y, attrs)
    end
    
    def polyline(*points)
      attrs = points.last.is_a?(Hash) ? points.pop : { }
      @contents << Shape.new(:polyline, attrs.merge(:points => points))
    end
    
    def polygon(*points)
      attrs = points.last.is_a?(Hash) ? points.pop : { }
      @contents << Shape.new(:polygon, attrs.merge(:points => points))
    end
    
    def text(contents, x, y, attrs = { })
      @contents << Text.new(contents, attrs.merge(:x => x, :y => y))
    end
    
    def build(&builder)
      builder.arity == 1 ? builder[self] : instance_eval(&builder)
    end
    
    def g(attrs = { }, &builder)
      @contents << Group.new(attrs)
      @contents.last.build(&builder) if builder
    end
    alias_method :group, :g
    
    def write(io_or_str, indent = '')
      return if empty? and @name != 'svg'
      super(io_or_str, indent) do |i_or_s|
        @contents.each { |shape| shape.write(i_or_s, indent + "  ") }
      end
    end
  end
  
  class Image < Group
    def initialize(width, height, &builder)
      super( :width   => width,
             :height  => height,
             :version => 1.1,
             :xmlns   => 'http://www.w3.org/2000/svg' )
      @name = 'svg'
      build(&builder) if builder
    end
    
    def [](index_or_title)
      if index_or_title.is_a? Numeric
        super
      else
        find { |shape| shape.attrs['title'] == index_or_title }
      end
    end
    
    def write(io_or_str, stand_alone = true)
      if stand_alone
        io_or_str << "<?xml version=\"1.0\"?>\n"                          <<
                     "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\"\n" <<
                     "  \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n"
      end
      super(io_or_str)
    end
    
    def to_s(stand_alone = true)
      str = ''
      write(str, stand_alone)
      str
    end
  end
end
