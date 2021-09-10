module Scar
  # This module contains basic easing definitions like `EaseInOut`
  module Easing
    # Base struct for an easing definition
    abstract struct EasingDefinition
      # Implement whatever your easing needs in this function
      #
      # *lf* is the linear fraction the `Tween` currently is at.
      abstract def calc(lf : Float32) : Float32
    end

    # Creates a struct inheriting `EasingDefinition` with the given name and `#calc` method
    #
    # Example usage (defining quadratic ease-in):
    # ```
    # simple_easing_function(:EaseInQuad, "lf ** 2")
    #
    # # This becomes:
    # struct EaseInQuad < EasingDefinition
    #   def calc(lf : Float32) : Float32
    #     lf ** 2
    #   end
    # end
    # ```
    macro simple_easing_function(name, fn)
      # Simple easing definition ({{ name.id }})
      struct {{name.id}} < EasingDefinition
        # The empty comment below is used to hide the docstring from `EasingDefinition`

        #
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

    # Can compute a 4 point Bezier curve easing.
    # Adapted from CSS browser implementations.
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

      # :nodoc:
      def initialize(@x1 : Float64, @y1 : Float64, @x2 : Float64, @y2 : Float64)
        @cx = 3.0 * @x1
        @bx = 3.0 * (@x2 - @x1) - @cx
        @ax = 1.0 - @cx - @bx

        @cy = 3.0 * @y1
        @by = 3.0 * (@y2 - @y1) - @cy
        @ay = 1.0 - @cy - @by
      end

      private def sample_curve_x(t)
        ((@ax * t + @bx) * t + @cx) * t
      end

      private def sample_curve_y(t)
        ((@ay * t + @by) * t + @cy) * t
      end

      private def sample_curve_derivative_x(t)
        ((3 * @ax * t + 2 * @bx) * t + @cx)
      end

      private def solve_curve_x(x, epsilon)
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

      #
      def calc(lf : Float32) : Float32
        calc(lf, 1e-5)
      end

      # Sample the curve with the given *epsilon* value
      def calc(lf : Float32, epsilon : Float64) : Float32
        return lf if @x1 == @y1 && @x2 == @y2
        sample_curve_y(solve_curve_x(lf, epsilon)).to_f32
      end
    end
  end

  # This class provides simple [inbe**tween**ing](https://en.wikipedia.org/wiki/Inbetweening) functionality.
  #
  # You create a `Tween` with the parameters of animation duration and easing function.
  # The obviously determines how long the `Tween` takes to complete,
  # the easing function determines how the tween calculates its values.
  #
  # A `Tween` is handled by an `App` after you register it via `App#tween`.
  #
  # Example usage:
  # ```
  # # Move the player 100 pixels to the right over the course of 5 seconds
  # origin = player.x
  # t = Scar::Tween.new(
  #   5,
  #   Scar::Easing::EaseInOutQuad,
  #   ->(t : Tween) { player.x = origin + t.fraction },
  #   ->(t : Tweeen) { puts "Player movement complete." }
  # )
  # app.tween(t)
  # ```
  class Tween
    getter :on_update
    getter :on_completed
    # Can be used to pause the Tween, meaning that its `#fraction` will stay the same until `@paused` is false again
    setter :paused

    def paused?
      @paused
    end

    getter :aborted

    @paused = false
    @aborted = false
    @duration : Float32

    # Creates a new tween with the following parameters (see details):
    #
    # - *duration*: The tweening duration
    # - *ease*: The `Easing::EasingDefinition` used to calculate the Tweens' values
    # - *on_update*: This hook is called on every frame, implement whatever tweening logic you have in here
    # - (optional) *on_completed*: This hook is called when the Tweens' duration is over (you could e. g. use this to chain Tweens)
    def initialize(duration : Number, @ease : Easing::EasingDefinition, @on_update : Proc(Tween, Nil), @on_completed : Proc(Tween, Nil) = ->(t : Tween) {})
      @duration = duration.to_f32
      @time_spent = 0f32
    end

    # Returns the current linear interpolated fraction (time spent / duration)
    def linear_fraction
      raw_fraction = @time_spent / @duration
      raw_fraction > 1f32 ? 1f32 : raw_fraction
    end

    # Returns the current interpolated fraction (calculated by the `Easing::EasingDefinition`)
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

    # Ends the tween **without** calling the `on_completed` hook
    def abort
      @aborted = true
    end

    # (used internally) Advances the `Tween` by the given delta time
    def update(delta_time)
      return if @aborted
      unless paused?
        @time_spent += delta_time
        @on_update.call(self)
      end
      if completed?
        @on_completed.call(self)
      end
    end

    # This macro can be used for very simple value tweening
    #
    # Example usage:
    # ```
    # tween Tween.bind_value(3, Easing::EaseInOutQuint.new, x, "80 *")
    # # This expands to
    # Tween.new(3, Easing::EaseInOutQuint.new, ->(t : Tween) { x = 80 * t.fraction }, ->(t : Tween) {})
    # ```
    #
    # Note that this does not work with individual entity transform components like `e.position.x`, as updating
    # these directly does not update the underlying `SF::Transform`. You have to set `e.position` as a whole.
    macro bind_value(duration, ease, val, modifier = "", on_completed = ->(t : Tween) {})
      Tween.new({{ duration }}, {{ ease }}, ->(t: Tween) { {{ val.id }} = {{ modifier.id }} t.fraction }, {{ on_completed }})
    end
  end # End class Tween
end   # End module Scar
