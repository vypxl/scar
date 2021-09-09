module Scar
  # This module contains the abstract base struct for all events in the Scar game library `Scar::Event::Event`
  # and all builtin events (including wrappers for all SFML events).
  module Event
    extend self

    # Base class for events
    #
    # An event can be triggered by anything in an application.
    # An event should only contain data, no methods.
    #
    # Inherit from this to define your own events.
    #
    # See `App` for usage.
    abstract struct Event; end

    # Predefined events

    # SFML Event Wrappers

    # Converts a raw SFML Event to the matching event wrapper (used internally)
    def from_sfml_event(e)
      case e
      when SF::Event::Closed
        Closed.new
      when SF::Event::Resized
        Resized.new(Vec.new(e.width.to_f32, e.height.to_f32))
      when SF::Event::LostFocus
        LostFocus.new
      when SF::Event::GainedFocus
        GainedFocus.new
      when SF::Event::TextEntered
        TextEntered.new(e.unicode)
      when SF::Event::KeyPressed
        KeyPressed.new(e.code, e.alt, e.control, e.shift, e.system)
      when SF::Event::KeyReleased
        KeyReleased.new(e.code, e.alt, e.control, e.shift, e.system)
      when SF::Event::MouseWheelScrolled
        MouseWheelScrolled.new(e.wheel, e.delta, e.x, e.y)
      when SF::Event::MouseButtonPressed
        MouseButtonPressed.new(e.button, e.x, e.y)
      when SF::Event::MouseButtonReleased
        MouseButtonReleased.new(e.button, e.x, e.y)
      when SF::Event::MouseMoved
        MouseMoved.new(e.x, e.y)
      when SF::Event::MouseEntered
        MouseEntered.new
      when SF::Event::MouseLeft
        MouseLeft.new
      when SF::Event::JoystickButtonPressed
        JoystickButtonPressed.new(e.joystick_id, e.button)
      when SF::Event::JoystickButtonReleased
        JoystickButtonReleased.new(e.joystick_id, e.button)
      when SF::Event::JoystickConnected
        JoystickConnected.new(e.joystick_id)
      when SF::Event::JoystickDisconnected
        JoystickDisconnected.new(e.joystick_id)
      when SF::Event::TouchBegan
        TouchBegan.new(e.finger, e.x, e.y)
      when SF::Event::TouchMoved
        TouchMoved.new(e.finger, e.x, e.y)
      when SF::Event::TouchEnded
        TouchEnded.new(e.finger, e.x, e.y)
      else
        nil
      end
    end

    # Window received an exit signal
    struct Closed < Event; end

    # Window was resized
    struct Resized < Event
      # The new size
      getter :size

      def initialize(@size : Vec); end
    end

    # Window lost Focus
    struct LostFocus < Event; end

    # Window gained Focus
    struct GainedFocus < Event; end

    # A unicode char was entered
    #
    # This is not a key event, it captures any entered unicode char entered by
    # any input method. This captures things like ^+e => ê.
    struct TextEntered < Event
      # The entered unicode character
      getter :unicode

      def initialize(@unicode : UInt32); end
    end

    # A key was pressed
    struct KeyPressed < Event
      # The keycode of the pressed key
      getter :code
      getter :alt
      getter :control
      getter :shift
      getter :system

      def initialize(@code : SF::Keyboard::Key, @alt : Bool, @control : Bool, @shift : Bool, @system : Bool); end
    end

    # A key was released
    struct KeyReleased < Event
      # The keycode of the released key
      getter :code
      getter :alt
      getter :control
      getter :shift
      getter :system

      def initialize(@code : SF::Keyboard::Key, @alt : Bool, @control : Bool, @shift : Bool, @system : Bool); end
    end

    # The mouse wheel was scrolled
    struct MouseWheelScrolled < Event
      getter :wheel
      getter :delta
      getter :x
      getter :y

      def initialize(@wheel : SF::Mouse::Wheel, @delta : Float32, @x : Int32, @y : Int32); end
    end

    # A mouse button was pressed
    struct MouseButtonPressed < Event
      getter :button
      getter :x
      getter :y

      def initialize(@button : SF::Mouse::Button, @x : Int32, @y : Int32); end
    end

    # A mouse button was released
    struct MouseButtonReleased < Event
      getter :button
      getter :x
      getter :y

      def initialize(@button : SF::Mouse::Button, @x : Int32, @y : Int32); end
    end

    # The mouse was moved
    struct MouseMoved < Event
      getter :x
      getter :y

      def initialize(@x : Int32, @y : Int32); end
    end

    # The mouse cursor entered the window
    struct MouseEntered < Event; end

    # The mouse cursor left the window
    struct MouseLeft < Event; end

    # A joystick button was pressed
    struct JoystickButtonPressed < Event
      getter :joystick_id
      getter :button

      def initialize(@joystick_id : UInt32, @button : UInt32); end
    end

    # A joystick button was released
    struct JoystickButtonReleased < Event
      getter :joystick_id
      getter :button

      def initialize(@joystick_id : UInt32, @button : UInt32); end
    end

    # A joystick was connected
    struct JoystickConnected < Event
      getter :joystick_id

      def initialize(@joystick_id : UInt32); end
    end

    # A joystick was disconnected
    struct JoystickDisconnected < Event
      getter :joystick_id

      def initialize(@joystick_id : UInt32); end
    end

    # A touch began
    struct TouchBegan < Event
      getter :finger
      getter :x
      getter :y

      def initialize(@finger : UInt32, @x : Int32, @y : Int32); end
    end

    # An existing touch moved
    struct TouchMoved < Event
      getter :finger
      getter :x
      getter :y

      def initialize(@finger : UInt32, @x : Int32, @y : Int32); end
    end

    # A touch ended
    struct TouchEnded < Event
      getter :finger
      getter :x
      getter :y

      def initialize(@finger : UInt32, @x : Int32, @y : Int32); end
    end

    #####################
    # END   SFML EVENTS #
    # START SCAR EVENTS #
    #####################

    # None at this point of development lol

  end # End module Event
end   # End module Scar
