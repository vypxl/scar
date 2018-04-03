module Scar
  module Event
    extend self

    # An event only has content, not functionality. Inherit from it to define your own.
    # See App for usage.
    abstract struct Event; end

    # Predefined events

    # SFML Event Wrappers

    def from_sfml_event(e)
      case e
      when SF::Event::Closed
        Closed.new
      when SF::Event::Resized
        Resized.new(Vec.new(e.width.to_f32, e.height.to_f32))
      else
        PlaceHolderCuzIDidNotHaveTimeToDefineAllEventsLol.new
      end
    end

    struct Closed < Event; end
    struct Resized < Event
      getter :size
      def initialize(@size : Vec); end
    end
    struct PlaceHolderCuzIDidNotHaveTimeToDefineAllEventsLol < Event; end
  end # End module Event
end # End module Scar
