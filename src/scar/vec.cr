# The Vector class used throughout the `Scar` game library.
# This is just an alias to `SF::Vector2`, but that struct was enhanced with utility methods.
# Just see `SF::Vector2`
alias Scar::Vec = SF::Vector2(Float32)

module SF
  # The utility methods `Scar` adds to `SF::Vector2` are documented here
  #
  # See also [CrSFML Documentation](https://oprypin.github.io/crsfml/api/SF/Vector2.html)
  struct Vector2(T)
    include Comparable(SF::Vector2(T))
    include Comparable(Float32)
    include Comparable(Float64)

    # Creates a vector from polar coordinates
    def self.from_polar(angle, radius = 1.0)
      self.new(radius * Math.cos(angle), radius * Math.sin(angle))
    end

    # Returns the [manhattan distance](https://en.wikipedia.org/wiki/Taxicab_geometry) of this vector's destination from the origin
    def manhattan
      x.abs + y.abs
    end

    # Returns the [manhattan distance](https://en.wikipedia.org/wiki/Taxicab_geometry) to another point
    def manhattan(other : SF::Vector2(T))
      (other.x - x).abs + (other.y - y).abs
    end

    # Returns the euclidean distance to another point
    def dist(other : SF::Vector2(T))
      Math.sqrt((x - other.x) ** 2 + (y - other.y) ** 2)
    end

    # Returns a vector with the same x and y but both positive
    def abs
      typeof(self).new(x.abs, y.abs)
    end

    # Compares two Vectors based on length
    def <=>(other : SF::Vector2f)
      length <=> other.length
    end

    # Compares this vector's length to the given scalar
    def <=>(length : Float32)
      length <=> other
    end

    # :ditto:
    def <=>(other : Float64)
      length.to_f64 <=> other
    end

    # :ditto:
    def <=>(other)
      self <=> other.to_f32
    end

    # Equality to a scalar: returns true if length is equal to *other*
    #
    # Epsilon is 1e-5
    def ==(other : Number)
      (self.length - other.to_f32).abs <= 1e-5
    end

    # Returns the dot product between two vectors
    def dot(other : SF::Vector2(T))
      x * other.x + y * other.y
    end

    # Returns the `z` component of the cross product of two vectors
    def cross(other : SF::Vector2(T))
      x * other.y - y * other.x
    end

    def length
      Math.sqrt((x * x) + (y * y))
    end

    # Same as length
    def magnitude
      length
    end

    def length_squared
      (x * x) + (y * y)
    end

    # Same as length_squared
    def magnitude_squared
      length_squared
    end

    # Returns a vector with the same direction of the original vector, but with a length of one unit
    def unit
      l = length
      l != 0 ? self / length : self
    end

    # :ditto:
    def normalized
      unit
    end

    # Returns this vector rotated by the given angle around the origin
    def rotate(angle : Float32)
      typeof(self).new(x * Math.cos(angle) - y * Math.sin(angle),
        x * Math.sin(angle) + y * Math.cos(angle))
    end

    # :ditto:
    def rotate(angle)
      rotate(angle.to_f32)
    end

    # Returns the angle between the vector and the x-axis
    def angle
      Math.atan2(y, x)
    end

    # Returns the angle between this Vector and another (the sign indicates which Vector is ahead)
    def angle_to(other : SF::Vector2f)
      Math.atan2(other.y, other.x) - Math.atan2(y, x)
    end

    # Returns a copy of self with a new x value
    def new_x(nx)
      typeof(self).new(nx, y)
    end

    # Returns a copy of self with a new y value
    def new_y(ny)
      typeof(self).new(x, ny)
    end
  end
end
