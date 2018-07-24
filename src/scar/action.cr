module Scar
  # Use this for one time actions.
  abstract class Action
    abstract def completed?(dt : Float32)

    def on_start; end

    def on_end; end
  end

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
