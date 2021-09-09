module Scar
  # Base class for Scar powered applications
  #
  # Example usage:
  # ```
  # # Define your app
  # class MyApp < Scar::App
  #   @counter = 0
  #
  #   def init
  #     puts "Loading Assets..."
  #     puts "Setting up the scene..."
  #   end
  #
  #   def update
  #     @counter += 1
  #   end
  #
  #   def render
  #     puts "Rendering the scene..."
  #   end
  # end
  #
  # # Create a window to render to
  # window = SF::RenderWindow.new(SF::VideoMode.new(1600, 900), "MyApp", SF::Style::Close)
  #
  # # Instatiate your app
  # app = MyApp.new(window)
  #
  # # Run your app
  # app.run
  # ```
  abstract class App
    # Returns the `SF::RenderWindow` of the app.
    getter :window
    # Returns the input handler of the app.
    getter :input
    # Returns the current scenes
    getter :scene_stack
    # Returns all currently running actions
    getter :actions

    # Set this to `true` to enable hot-reloading of assets
    property hotreload = false

    # App specific initialization
    #
    # e. g. loading configuration, binding inputs, loading textures, ..
    abstract def init

    # App update logic
    #
    # This method is executed on every frame **before** all `System` and `Object` update methods.
    abstract def update(dt)

    # App rendering logic
    #
    # This method is executed on every frame **before** all `System` and `Object` rendering methods.
    abstract def render(dt)

    # Initializes the app with a RenderWindow as a render target and an input handler
    def initialize(@window : SF::RenderWindow, @input : Input = Input.new)
      @next_id = 0u64
      @time = Time.utc
      @scene_stack = Array(Scene).new
      @tweens = Array(Tween).new
      @actions = Array(Action).new
      init()
    end

    # Starts the app and begins running the event loop
    def run
      time = Time.utc
      while window.open?
        while e = window.poll_event
          converted = Event.from_sfml_event(e)
          broadcast converted if converted
        end

        new_time = Time.utc
        dt = (new_time - time).total_seconds
        Assets.check_hotreload(dt)
        @tweens.each(&.update dt)
        @tweens.select! { |t| !t.completed? }
        @actions.select! { |a| res = a.completed?(dt); a.on_end if res; !res }
        update dt
        render dt
        if @scene_stack.last?
          @scene_stack.last.update(self, dt)
          @scene_stack.last.render(self, dt)
        end
        @window.display
        time = new_time
      end
    end

    # Unloads assets and exits the program.
    #
    # Override this method if you have specific exit logic.
    # Note that it is recommended that you call super() during you custom exit method.
    def exit(status = 0)
      Assets.unload_all
      window.close
      window.finalize
      Process.exit(status)
    end

    # The following methods are just there for the docs generator,
    # the actual implementation is inside the `finished` macro later

    # Adds an event handler for the specified event type and returns its id
    #
    # The block must have a type of `Proc(event_type, Nil)`.
    # This method is defined for every subtype of Scar::Event, other types will generate a compiler error.
    # Exampe usage:
    # ```
    # app.subscibe(Scar::Event::Resized) { |evt| puts "Resized!" }
    # ```
    def subscribe(event_type, &block) : UInt64
      {% raise "Invalid event type" %}
    end

    # Broadcasts the given event (calls all event listeners)
    #
    # Example usage:
    # ```
    # app.broadcast(Scar::Event::Closed.new)
    # ```
    def broadcast(event)
      raise "Invalid event type"
    end

    macro finished
      {% for evt in Event::Event.subclasses %}
        @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}} = Hash(UInt64, ({{evt}}->)).new

        # :nodoc:
        def subscribe(event_type : {{evt}}.class, &block : {{evt}}->) : UInt64
          @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}[@next_id] = block
          @next_id += 1
          @next_id - 1
        end

        # :nodoc:
        def broadcast(event : {{evt}})
          @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}.each do |_, handler|
            handler.call(event)
          end
        end
      {% end %} # End macro-for

      # Deletes the event handler with the given id
      def unsubscribe(id)
        {% for evt in Event::Event.subclasses %}
          if @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}[id]?
            @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}.delete id
          end
        {% end %}
      end
    end # End macro finished

    # Push a scene onto the scene stack
    delegate :<<, to: @scene_stack
    # Pop a scene from the scene stack
    delegate pop, to: @scene_stack

    # Registers a `Tween` which is then updated on every frame.
    #
    # The `Tween` will be deleted when `Tween#completed?` returns true after an update.
    # If the Tween restarts itself in `Tween#on_completed` (e. g. by calling `Tween#reset`)
    # or does anything that prevents the `Tween#completed?` check, it will not be deleted.
    def tween(t : Tween)
      @tweens << t
      t
    end

    # Begin running an `Action`
    def act(action : Action)
      @actions << action
      action.on_start
    end

    # Returns the topmost scene on the scene stack (convenience method)
    def scene
      @scene_stack.last
    end
  end # End class App
end   # End module Scar
