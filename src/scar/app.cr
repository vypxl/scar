require "crsfml"

module Scar
  # A Scar powered application.
  abstract class App
    # Returns the SFML RenderWindow of the app.
    getter :window
    # Returns the input handler of the app.
    getter :input
    # Returns the current scenes
    getter :scene_stack
    # Returns the current running actions
    getter :actions

    # App specific initialization (load config, bind inputs(based on config), load textures...).
    abstract def init

    # General App update logic; executed before all System updates.
    abstract def update(dt)

    # General App rendering logic; executed before all System rendering.
    abstract def render(dt)

    # Initializes the app with an RenderWindow and an input handler.
    def initialize(@window : SF::RenderWindow, @input : Input)
      @next_id = 0u64
      @time = Time.now
      @scene_stack = Array(Scene).new
      @tweens = Array(Tween).new
      @actions = Array(Action).new
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
        # @window.clear(SF::Color::Black)
        @tweens.each { |t| t.update dt }
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
    end # End run

    # Unloads Assets and exits the program. Override if you have specific exit logic.
    def exit(status = 0)
      Assets.unload_all
      window.close
      window.finalize
      Process.exit(status)
    end # End exit

    macro finished
      {% for evt in Event::Event.subclasses %}
        @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}} = Hash(UInt64, ({{evt}}->)).new

        # Adds an event handler for {{evt}} and returns its id.
        def subscribe(%event_type : {{evt}}.class, &block : {{evt}} ->) : UInt64
          @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}[@next_id] = block
          @next_id += 1
          @next_id - 1
        end # End subscribe

        # Broadcasts an {{evt}} Event.
        def broadcast(%event : {{evt}})
          @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}.each do |_, handler|
            handler.call(%event)
          end
        end # End broadcast
      {% end %} # End macro-for

      # Deletes the event handler with the given id.
      def unsubscribe(%id)
        {% for evt in Event::Event.subclasses %}
          if @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}[%id]?
            @event_handlers_{{evt.id.gsub(/::/, "__").id.downcase}}.delete %id
          end
        {% end %}
      end # End unsubscribe
    end # End macro finished

    delegate :<<, to: @scene_stack
    delegate pop, to: @scene_stack

    # Creates a tween which is then updated simultaneously with the app. Is deleted when #complete? after update. See details.
    # If the Tween restarts itself in on_complete (by calling `Tween#reset` for example)
    # or does anything that prevents the `Tween#complete?` check, it is NOT deleted!
    def tween(duration, ease : Easing::EasingDefinition, on_update : Proc(Tween, Nil) = ->(t : Tween){}, on_complete : Proc(Tween, Nil) = ->(t : Tween){})
      @tweens << Tween.new(duration.to_f32, ease, on_update, on_complete)
    end

    # Run an Action
    def act(action : Action)
      @actions << action
      action.on_start
    end

    # Returns current scene for convenience
    def scene
      @scene_stack.last
    end
  end # End class App
end   # End module Scar
