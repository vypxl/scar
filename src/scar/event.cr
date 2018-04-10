module Scar
  module Event
    extend self

    # An event only has content, not functionality. Inherit from it to define your own.
    # See App for usage.
    abstract struct Event; end

    # Predefined events

    # SFML Event Wrappers

    # Converts a raw SFML Event to the matching Event wrapper.
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

    # Window got an exit signal.
    struct Closed < Event; end

    # Window got Resized (size : Vec).
    struct Resized < Event
      getter :size

      def initialize(@size : Vec); end
    end

    # Window lost Focus.
    struct LostFocus < Event; end

    # Window gained Focus.
    struct GainedFocus < Event; end

    # Window got unicode char entered (unicode : UInt32).
    # This is not a Key event, it captures any entered unicode char entered by
    # any input method. This can capture things like ^+e => ê.
    struct TextEntered < Event
      getter :unicode

      def initialize(@unicode : UInt32); end
    end

    # Key was pressed (code : SF::Keyboard::Key, alt control shift system : Bool).
    struct KeyPressed < Event
      getter :code
      getter :alt
      getter :control
      getter :shift
      getter :system

      def initialize(@code : SF::Keyboard::Key, @alt : Bool, @control : Bool, @shift : Bool, @system : Bool); end
    end

    # Same as KeyPressed but it was released.
    struct KeyReleased < Event
      getter :code
      getter :alt
      getter :control
      getter :shift
      getter :system

      def initialize(@code : SF::Keyboard::Key, @alt : Bool, @control : Bool, @shift : Bool, @system : Bool); end
    end

    # Mouse wheel got scrolled (wheel : SF::Mouse::Wheel, delta : Float32, x y : Int32).
    struct MouseWheelScrolled < Event
      getter :wheel
      getter :delta
      getter :x
      getter :y

      def initialize(@wheel : SF::Mouse::Wheel, @delta : Float32, @x : Int32, @y : Int32); end
    end

    # Mouse button was pressed (button : SF::Mouse::Button, x y : Int32).
    struct MouseButtonPressed < Event
      getter :button
      getter :x
      getter :y

      def initialize(@button : SF::Mouse::Button, @x : Int32, @y : Int32); end
    end

    # Same as MouseButtonPressed but it was released.
    struct MouseButtonReleased < Event
      getter :button
      getter :x
      getter :y

      def initialize(@button : SF::Mouse::Button, @x : Int32, @y : Int32); end
    end

    # Mouse was moved (x y : Int32).
    struct MouseMoved < Event
      getter :x
      getter :y

      def initialize(@x : Int32, @y : Int32); end
    end

    # Mouse entered the window.
    struct MouseEntered < Event; end

    # Mouse left the window.
    struct MouseLeft < Event; end

    # Joystick button got pressed (joystick_id button : UInt32).
    struct JoystickButtonPressed < Event
      getter :joystick_id
      getter :button

      def initialize(@joystick_id : UInt32, @button : UInt32); end
    end

    # Same as JoystickButtonPressed but it was released.
    struct JoystickButtonReleased < Event
      getter :joystick_id
      getter :button

      def initialize(@joystick_id : UInt32, @button : UInt32); end
    end

    # A Joystick connected (joystick_id : UInt32).
    struct JoystickConnected < Event
      getter :joystick_id

      def initialize(@joystick_id : UInt32); end
    end

    # Same as JoystickConnected but it disconnected.
    struct JoystickDisconnected < Event
      getter :joystick_id

      def initialize(@joystick_id : UInt32); end
    end

    # A touch began (finger : UInt32, x y : Int32).
    struct TouchBegan < Event
      getter :finger
      getter :x
      getter :y

      def initialize(@finger : UInt32, @x : Int32, @y : Int32); end
    end

    # Same as TouchBegan but it moved.
    struct TouchMoved < Event
      getter :finger
      getter :x
      getter :y

      def initialize(@finger : UInt32, @x : Int32, @y : Int32); end
    end

    # Same as TouchBegan but it ended.
    struct TouchEnded < Event
      getter :finger
      getter :x
      getter :y

      def initialize(@finger : UInt32, @x : Int32, @y : Int32); end
    end
  end # End module Event
end   # End module Scar
