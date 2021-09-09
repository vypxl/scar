module Scar
  # A Space is a container for one independent layer of your application,
  # like UI, Game World, Background, ...
  #
  # A space contains `Entity`s and `System`s.
  #
  # Spaces live inside `Scene`s.
  #
  # Spaces should not interact with each other.
  #
  # Each `Space` has a default camera object, accessible through space#camera.
  # The camera object has the entity id `__camera`.
  #
  # Example usage:
  # ```
  # # Create a space with the id "ui", a system and two entities
  # sp = Scar::Space.new("ui", UpdateUISystem, health_bar, exit_button, 1)
  # scene << sp
  # ```
  class Space
    # The z-coordinate of this space, used to specify the rendering order of multiple spaces
    property z
    property id
    # The default `Camera` object
    property camera
    # :nodoc:
    getter :systems, :entities

    # Make the default camera use it's SFML View, so it can be configured more easily
    @camera : Objects::Camera = Objects::Camera.new("__camera")

    def initialize(@id : String, @z : Int32 = 0)
      @entities = Array(Entity).new
      @systems = Array(System).new

      self << @camera
    end

    def initialize(@id : String, *entities_or_systems : Entity | System, @z : Int32 = 0)
      @entities = Array(Entity).new
      @systems = Array(System).new

      entities_or_systems.each { |e| self << e }

      self << @camera
    end

    # :nodoc:
    # TODO: initialize systems and objects when they are inserted; remove their initialized property
    def update(app, dt)
      @systems.each do |s|
        if !s.initialized
          s.init(app, self)
          s.initialized = true
        end
        s.update(app, self, dt)
      end

      @entities.each do |e|
        if e.is_a? Object
          if !e.initialized
            e.init(app, self)
            e.initialized = true
          end
          e.update(app, self, dt)
        end
      end

      @entities.select!(&.alive?)
    end

    # :nodoc:
    def render(app, dt)
      @entities.each do |e|
        e.render_view(app, self, dt) if e.is_a? Objects::Camera
      end
    end

    # TODO: fail at entity id duplicates

    # Adds an Entity to the space and returns self
    def <<(entity : Entity)
      idx = 0
      @entities.each_with_index do |e, i|
        idx = i
        break if e.z > entity.z
      end
      @entities.insert(idx, entity)
      self
    end

    # Adds a System to the space and returns self
    def <<(sys : System)
      @systems << sys
      self
    end

    # Adds multiple Entities or Systems to the space and returns self
    def <<(*entities_or_systems : Entity | System)
      entities_or_systems.each { |e| self << e }
      self
    end

    # For each Entity having the given component in the space, yield the entity and it's component
    def each_with(comp_type : T.class, &block : ((Entity, T) ->)) forall T
      @entities.each { |e|
        c = e[comp_type]?
        yield e, c if c
      }
    end

    # For each Entity having the given components in the space, yield the entity and it's *comp_type* component
    #
    # Example usage:
    # ```
    # # Subtract hp from every enemy entity in the player's range
    # space.each_with(EnemyComponent, Scar::Components::Sprite) do |ent, comp|
    #   comp.hp -= 10 if player.in_range?(ent)
    # end
    # ```
    def each_with(comp_type : T.class, *other_comp_types : Component.class, &block : ((Entity, T) ->)) forall T
      @entities.each { |e|
        c = e[comp_type]?
        yield e, c if c && e.has? *other_comp_types
      }
    end

    # Returns the `Entity` with given id
    def [](id : String) : Entity
      x = self[id]?
      if x.nil?
        Logger.fatal "No Entity with id '#{id}' found!"
      else
        x
      end
    end

    # Returns the `Entity` with given id or return `nil` of no entity is found
    def []?(id : String) : Entity | Nil
      @entities.find { |e| e.id == id }
    end
  end # End class Space
end   # End module Scar
