require "crsfml"
require "chipmunk"

module Scar
  struct Vec
    property :x
    property :y

    def initialize(x, y)
      initialize(x.to_f32, y.to_f32)
    end

    def initialize(@x : Float32, @y : Float32); end

    # From SF::Vector2
    def from(v : SF::Vector2)
      self.new(v.x, v.y)
    end

    # From CP::Vector
    def fom(v : CP::Vector)
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
      Vec.new(x / other.x, y * other.y)
    end

    # Scales the Vector by the scalar
    def *(scalar : Float32)
      Vec.new(x * scalar, y * scalar)
    end

    # Scales the Vector by 1 / the scalar
    def /(scalar : Float32)
      Vec.new(x / scalar, y / scalar)
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
      Math.sqrt(a.x ** 2 + b.x ** 2)
    end

    def length_squared
      a.x ** 2 + b.x ** 2
    end

    # Same vector, but length is one
    def unit
      self / self.length
    end

    # Same vector, but length is one
    def normalized
      unit
    end

    # Rotate by angle
    def rotate(angle : Float32)
      Vec2.new(x * Math.cos(angle) - y * Math.sin(angle),
        x * Math.sin(angle) + y * Math.cos(angle))
    end

    def angle
      Math.atan2(y, x)
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
