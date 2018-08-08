require "crsfml"
require "chipmunk"

module Scar
  struct Vec
    include Comparable(Vec)
    include Comparable(Float32)
    include Comparable(Float64)

    property :x
    property :y

    def initialize(@x : Float32, @y : Float32)
    end

    def initialize(x, y)
      initialize(x.to_f32, y.to_f32)
    end

    def initialize
      initialize(0, 0)
    end

    # From SF::Vector2
    def self.from(v : SF::Vector2)
      self.new(v.x, v.y)
    end

    # From CP::Vector
    def self.from(v : CP::Vect)
      self.new(v.x, v.y)
    end

    # Component wise Addition
    def +(other : Vec)
      Vec.new(x + other.x, y + other.y)
    end

    # Component wise Substraction
    def -(other : Vec)
      Vec.new(x - other.x, y - other.y)
    end

    # Component wise Multiplication
    def *(other : Vec)
      Vec.new(x * other.x, y * other.y)
    end

    # Component wise Division
    def /(other : Vec)
      Vec.new(x / other.x, y / other.y)
    end

    # Scales the Vector by the scalar
    def *(scalar)
      Vec.new(x * scalar, y * scalar)
    end

    # Scales the Vector by 1 / the scalar
    def /(scalar)
      Vec.new(x / scalar, y / scalar)
    end

    # Manhattan distance
    def manhattan
      x.abs + y.abs
    end

    # Returns a Vector with the same x and y but both positive
    def abs
      Vec.new(x.abs, y.abs)
    end

    # Comparison between Vectors
    def <=>(other : Vec)
      manhattan <=> other.manhattan
    end

    # Comparison based on length
    def <=>(other : Float32)
      length <=> other
    end

    def <=>(other : Float64)
      length.to_f64 <=> other
    end

    def <=>(other)
      Logger.debug("i")
      self <=> other.to_f32
    end

    # Length is within 1e-5 of other
    def ==(other : Number)
      (self.length - other.to_f32).abs <= 1e-5
    end

    # Dot product
    def dot(other : Vec)
      x * other.x + y * other.y
    end

    # Z Component of Cross product
    def cross(other : Vec)
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
      Vec.new(x * Math.cos(angle) - y * Math.sin(angle),
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
    def angle_to(other : Vec)
      Math.atan2(other.y, other.x) - Math.atan2(y, x)
    end

    # Return copy of self with a new x value
    def new_x(nx)
      Vec.new(nx, y)
    end

    # Return copy of self with a new x value
    def new_y(ny)
      Vec.new(x, ny)
    end

    # Converts the vector to an SF::Vector2
    def sf
      SF::Vector2.new(x, y)
    end

    # Converts the vector to an Chipmunk::Vector
    def cp
      CP.v(x, y)
    end
  end # End struct Vec
end   # End module Scar
