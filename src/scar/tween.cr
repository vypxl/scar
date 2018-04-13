module Scar
  class Tween
    abstract class Kind
      abstract def calc(lf)

      class Linear < Kind
        def calc(lf)
          lf
        end
      end

      class EaseIn < Kind
        def calc(lf)
          lf * lf * lf
        end
      end

      class EaseOut < Kind
        @@ease_in = EaseIn.new

        def calc(lf)
          1f32 - @@ease_in.calc(1f32 - lf)
        end
      end

      class EaseInOut < Kind
        @@ease_in = EaseIn.new

        def calc(lf)
          if lf < 0.5
            @@ease_in.calc(lf * 2) / 2
          else
            1 - @@ease_in.calc((1 - lf) * 2) / 2
          end
        end
      end
    end

    property :on_update
    property :on_complete

    def initialize(duration : Float32, kind : Kind.class, on_update : Proc(Tween, Nil) = ->{}, on_complete : Proc(Tween, Nil) = ->{})
      initialize(duration, kind.new, on_update, on_complete)
    end

    def initialize(@duration : Float32, @kind : Kind, @on_update : Proc(Tween, Nil), @on_complete : Proc(Tween, Nil))
      @time_spent = 0f32
    end

    # Returns the current linear interpolated fraction
    def linear_fraction
      raw_fraction = @time_spent / @duration
      raw_fraction > 1f32 ? 1f32 : raw_fraction
    end

    # Returns the current interpolated fraction (defined by the kind)
    def fraction
      @kind.calc(linear_fraction)
    end

    def complete?
      linear_fraction == 1f32
    end

    # Sets @time_spent to 0 / starts the tween over.
    def reset
      @time_spent = 0f32
    end

    def update(delta_time)
      @time_spent += delta_time
      @on_update.call(self)
      if complete?
        @on_complete.call(self)
      end
    end
  end # End class Tween
end   # End module Scar
