module Scar
  # Use this for one time actions.
  abstract class Action
    abstract def completed?(dt : Float32)

    def on_start; end

    def on_end; end
  end
end
