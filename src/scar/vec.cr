module Scar
  alias Vec = SF::Vector2f

  struct SF::Vector2(T)
    include Comparable(SF::Vector2f)
    include Comparable(Float32)
    include Comparable(Float64)

    def initialize(x, y)
      @x = x.to_f32
      @y = y.to_f32
    end

    def dup
      typeof(self).new(@x, @y)
    end

    # From SF::Vector2
    def self.from(v : SF::Vector2)
      self.new(v.x, v.y)
    end

    # Create from polar coordinate
    def self.from_polar(angle : Float32, radius : Float32 = 1.0)
      self.new(radius * Math.cos(angle), radius * Math.sin(angle))
    end

    # Component wise Addition
    def +(other : SF::Vector2f)
      typeof(self).new(x + other.x, y + other.y)
    end

    # Component wise Substraction
    def -(other : SF::Vector2f)
      typeof(self).new(x - other.x, y - other.y)
    end

    # Component wise Multiplication
    def *(other : SF::Vector2f)
      typeof(self).new(x * other.x, y * other.y)
    end

    # Component wise Division
    def /(other : SF::Vector2f)
      typeof(self).new(x / other.x, y / other.y)
    end

    # Scales the Vector by the scalar
    def *(scalar)
      typeof(self).new(x * scalar, y * scalar)
    end

    # Scales the Vector by 1 / the scalar
    def /(scalar)
      typeof(self).new(x / scalar, y / scalar)
    end

    # Manhattan distance
    def manhattan
      x.abs + y.abs
    end

    # Distance to another point
    def dist(other : SF::Vector2f)
      Math.sqrt((x - other.x) ** 2 + (y - other.y) ** 2)
    end

    # Returns a Vector with the same x and y but both positive
    def abs
      typeof(self).new(x.abs, y.abs)
    end

    # Comparison between Vectors
    def <=>(other : SF::Vector2f)
      length <=> other.length
    end

    # Comparison based on length
    def <=>(other : Float32)
      length <=> other
    end

    def <=>(other : Float64)
      length.to_f64 <=> other
    end

    def <=>(other)
      self <=> other.to_f32
    end

    # Length is within 1e-5 of other
    def ==(other : Number)
      (self.length - other.to_f32).abs <= 1e-5
    end

    # Dot product
    def dot(other : SF::Vector2f)
      x * other.x + y * other.y
    end

    # Z Component of Cross product
    def cross(other : SF::Vector2f)
      x * other.y - y * other.x
    end

    def length
      Math.sqrt((x * x) + (y * y))
    end

    def magnitude
      length
    end

    def length_squared
      (x * x) + (y * y)
    end

    def magnitude_squared
      length_squared
    end

    # Same vector, but length is one
    def unit
      l = length
      l != 0 ? self / length : self
    end

    # Same vector, but length is one
    def normalized
      unit
    end

    # Rotate by angle
    def rotate(angle : Float32)
      typeof(self).new(x * Math.cos(angle) - y * Math.sin(angle),
        x * Math.sin(angle) + y * Math.cos(angle))
    end

    def rotate(angle)
      rotate(angle.to_f32)
    end

    # Returns the angle between the Vector and the x-axis
    def angle
      Math.atan2(y, x)
    end

    # Returns the angle between this Vector and another (sign indicates which Vector is ahead)
    def angle_to(other : SF::Vector2f)
      Math.atan2(other.y, other.x) - Math.atan2(y, x)
    end

    # Return copy of self with a new x value
    def new_x(nx)
      typeof(self).new(nx, y)
    end

    # Return copy of self with a new x value
    def new_y(ny)
      typeof(self).new(x, ny)
    end
  end # End struct Vec
end   # End module Scar
