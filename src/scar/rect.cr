module Scar
  alias Rect = SF::Rect
  alias Rectf = SF::Rect(Float32)
  alias Recti = SF::Rect(Int32)

  struct SF::Rect(T)
    def x
      left
    end

    def x=(v)
      left = v
    end

    def y
      top
    end

    def y=(v)
      top = v
    end

    def right
      left + width
    end

    def right=(v)
      width = v - left
    end

    def bottom
      top + height
    end

    def bottom=(v)
      height = v - top
    end
  end
end
