require "crsfml"

require "./*"

module Scar
  # A Scar powered application.
  abstract class App
    # Returns the SFML RenderWindow of the app.
    getter :window
    # Returns the input handler of the app.
    getter :input
    # Returns the current scenes
    getter :scene_stack

    # App specific initialization (load config, bind inputs(based on config), load textures...).
    abstract def init

    # App update logic.
    abstract def update(dt)

    # App rendering logic.
    abstract def render(dt)

    # Initializes the app with an RenderWindow and an input handler.
    def initialize(@window : SF::RenderWindow, @input : Input)
      @next_id = 0u32
      @time = Time.now
      @scene_stack = Array(Scene).new
      init()
    end # End initialize

    # Starts the app.
    # Update and render based on scene stack
    def run
      time = Time.now
      while window.open?
        while e = window.poll_event
          converted = Event.from_sfml_event(e)
          broadcast converted if converted
        end

        new_time = Time.now
        dt = (new_time - time).total_seconds
        if @scene_stack.last?
          @scene_stack.last.update(self, dt)
          @scene_stack.last.render(self, dt)
        end
        time = new_time
      end
    end # End run

    # Exits the app. Override if you have specific exit logic.
    def exit
      window.close
    end # End exit

    macro finished
      {% for evt in Event::Event.subclasses %}
        @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}} = Hash(UInt32, ({{evt}}->)).new

        # Adds an event handler for {{evt}} and returns its id.
        def subscribe(event_type : {{evt}}.class, &block : {{evt}} ->) : UInt32
          @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}[@next_id] = block
          @next_id += 1
          @next_id - 1
        end # End subscribe

        # Broadcasts an {{evt}} Event.
        def broadcast(event : {{evt}})
          @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}.each do |_, handler|
            handler.call(event)
          end
        end # End broadcast
      {% end %} # End macro-for

      # Deletes the event handler with the given id.
      def unsubscribe(id)
        {% for evt in Event::Event.subclasses %}
          if @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}[id]?
            @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}.delete id
          end
        {% end %}
      end # End unsubscribe
    end # End macro finished

    # Shortcut for @scene_stack#<<
    def <<(scene : Scene)
      @scene_stack << scene
    end

    # Shortcut for @scene_stack#push(*values : T)
    def <<(*scenes : Scene)
      @scene_stack.push scenes
    end

    # Shortcut for @scene_stack#pop
    def pop(&block)
      @scene_stack.pop(block)
    end
  end # End class App
end   # End module Scar
