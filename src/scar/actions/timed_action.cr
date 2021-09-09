module Scar::Actions
  # A simple action that waits for a specified amount of time before completing
  #
  # Sample usage:
  # ```
  # app.act Scar::Actions::Timed.new(5) { puts "Hello after 5 seconds" }
  # ```
  class Timed < Scar::Action
    @time : Float32 = 0

    # :nodoc:
    def initialize(@duration : Float32, @on_end : Proc(Nil))
    end

    # Creates a timed action that calls the given block after *duration* seconds
    def initialize(duration, &block)
      initialize(duration, block)
    end

    # :nodoc:
    def completed?(dt)
      @time += dt
      @time >= @duration
    end

    # :nodoc:
    def on_end
      @on_end.call
    end
  end
end
