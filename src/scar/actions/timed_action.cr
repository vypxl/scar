module Scar
  # Use this for delayed actions.
  class TimedAction < Action
    @time : Float32 = 0

    def initialize(@duration : Float32, @on_end : Proc(Nil))
    end

    def completed?(dt)
      @time += dt
      @time >= @duration
    end

    def on_end
      @on_end.call
    end
  end
end
