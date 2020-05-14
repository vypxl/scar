module Scar
  # Represents an xywh rectangle made of Float32
  struct Rect
    property :x, :y, :width, :height

    @x : Float32
    @y : Float32
    @width : Float32
    @height : Float32

    def initialize(x, y, width, height)
      @x = x.to_f32
      @y = y.to_f32
      @width = width.to_f32
      @height = height.to_f32
    end

    # Gets the intersection area between two rectangles
    def intersection(other : Rect)
      x = Math.max(@x, other.x)
      y = Math.max(@y, other.y)
      x2 = Math.min(@x + @width, other.x + other.width)
      y2 = Math.min(@y + @height, other.y + other.height)
      return self.new(x, y, x2 - x, y2 - y)
    end

    # Checks if two rectangles intersect
    def intersects?(other : Rect)
      @x < other.x + other.w && @x + @width > other.x && @y > other.y + other.height && @y + @height < other.y
    end

    # Checks if a point lies inside the rectangle
    def contains?(point : Vec)
      @x <= point.x && @x + @width >= point.x && @y <= point.y && @y + @height >= point.y
    end

    # Converts the rectangle to a SF::Rect
    def sf
      SF::Rect.new(@x, @y, @width, @height)
    end
  end
end
