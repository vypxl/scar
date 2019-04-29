module Scar
  # Basic easing functions
  module Easing
    # Inherit from this to create your own easing.
    abstract struct EasingDefinition
      abstract def calc(lf : Float32) : Float32

      def test(lf)
        0f32
      end
    end

    # Creates a EasingDefinition inherited struct with the given name and calc function as String
    macro simple_easing_function(name, fn)
      struct {{name.id}} < EasingDefinition
        def calc(lf : Float32) : Float32
          {{fn.id}}
        end
      end
    end

    simple_easing_function(:Linear, "lf")
    simple_easing_function(:EaseInQuad, "lf ** 2")
    simple_easing_function(:EaseOutQuad, "lf * (2 - lf)")
    simple_easing_function(:EaseInOutQuad, "lf < 0.5 ? 2 * lf ** 2 : -1 + (4 - 2 * lf) * lf")
    simple_easing_function(:EaseInCubic, "lf ** 3")
    simple_easing_function(:EaseOutCubic, "(lf - 1) ** 3 + 1")
    simple_easing_function(:EaseInOutCubic, "lf < 0.5 ? 4 * lf ** 3 : (lf - 1) * (2 * lf - 2) ** 2 + 1")
    simple_easing_function(:EaseInQuart, "lf ** 4")
    simple_easing_function(:EaseOutQuart, "1 - (lf - 1) ** 4")
    simple_easing_function(:EaseInOutQuart, "lf < 0.5 ? 8 * lf ** 4 : 1 - 8 * (lf - 1) ** 4")
    simple_easing_function(:EaseInQuint, "lf ** 5")
    simple_easing_function(:EaseOutQuint, "1 + (lf - 1) ** 5")
    simple_easing_function(:EaseInOutQuint, "lf < 0.5 ? 16 * lf ** 5 : 1 + 16 * (lf - 1) ** 5")

    # Use this instead of simple_easing_function ONLY if you need dynamically created easing functions.
    # Usage:
    # ```
    # Tween.new(1f32, EaseWithFunction.new(->(lf : Float32) { lf - 0.2 ** 3 }))
    # ```
    struct EaseWithFunction < EasingDefinition
      def initialize(@fn : Proc(Float32, Float32)); end

      def calc(lf : Float32)
        @fn.call(lf)
      end
    end

    # Can compute a 4 point Bezier curve easing.
    # Adapted from css browser implementations.
    struct CubicBezier < EasingDefinition
      @cx : Float64
      @bx : Float64
      @ax : Float64

      @cy : Float64
      @by : Float64
      @ay : Float64

      def initialize(x1, y1, x2, y2)
        initialize(x1.to_f64, y1.to_f64, x2.to_f64, y2.to_f64)
      end

      def initialize(@x1 : Float64, @y1 : Float64, @x2 : Float64, @y2 : Float64)
        @cx = 3.0 * @x1
        @bx = 3.0 * (@x2 - @x1) - @cx
        @ax = 1.0 - @cx - @bx

        @cy = 3.0 * @y1
        @by = 3.0 * (@y2 - @y1) - @cy
        @ay = 1.0 - @cy - @by
      end

      def sample_curve_x(t)
        ((@ax * t + @bx) * t + @cx) * t
      end

      def sample_curve_y(t)
        ((@ay * t + @by) * t + @cy) * t
      end

      def sample_curve_derivative_x(t)
        ((3 * @ax * t + 2 * @bx) * t + @cx)
      end

      def solve_curve_x(x, epsilon)
        t0 = 0.0
        t1 = 0.0
        t2 = x
        x2 = 0.0
        d2 = 0.0

        8.times do
          x2 = sample_curve_x(t2) - x
          return t2 if x2.abs < epsilon
          d2 = sample_curve_derivative_x(t2)
          break if d2.abs < 1e-6
          t2 = t2 - x2 / d2
        end

        t0 = 0.0
        t1 = 1.0
        t2 = x

        return t0 if t2 < t0
        return t1 if t2 < t1

        while t0 < t1
          x2 = sample_curve_x(t2)
          return t2 if (x2 - x).abs < epsilon
          if x > x2
            t0 = t2
          else
            t1 = t2
          end
          t2 = (t1 - t0) * 0.5 + t0
        end

        t2
      end

      def calc(lf : Float32) : Float32
        calc(lf, 1.0)
      end

      def calc(lf : Float32, epsilon : Float64) : Float32
        return lf if @x1 == @y1 && @x2 == @y2
        sample_curve_y(solve_curve_x(lf, epsilon)).to_f32
      end
    end
  end

  class Tween
    property :on_update
    property :on_completed
    property :paused
    property :aborted

    @paused = false
    @aborted = false

    def initialize(@duration : Float32, @ease : Easing::EasingDefinition, @on_update : Proc(Tween, Nil) = ->(t : Tween) {}, @on_completed : Proc(Tween, Nil) = ->(t : Tween) {})
      @time_spent = 0f32
    end

    # Returns the current linear interpolated fraction
    def linear_fraction
      raw_fraction = @time_spent / @duration
      raw_fraction > 1f32 ? 1f32 : raw_fraction
    end

    # Returns the current interpolated fraction (defined by the kind)
    def fraction : Float32
      @ease.calc(linear_fraction)
    end

    def completed?
      linear_fraction == 1f32
    end

    # Sets @time_spent to 0 / starts the tween over.
    def reset
      @time_spent = 0f32
    end

    # Ends the tween WITHOUT calling the on_completed hook
    def abort
      @aborted = true
    end

    def update(delta_time)
      return if @aborted
      if !@paused
        @time_spent += delta_time
        @on_update.call(self)
      end
      if completed?
        @on_completed.call(self)
      end
    end
  end # End class Tween
end   # End module Scar
