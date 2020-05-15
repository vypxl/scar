module Scar
  # A Space holds Entities and Systems. Spaces should not interact with each other
  # Each Space has a default camera object, accessible through space#camera, and a default Scar::Systems::RenderCameras system.
  # The camera object has the entity id `__camera`
  class Space
    property :entities, :systems, :z, :id, :camera

    @camera : Objects::Camera = Objects::Camera.new("__camera")

    def initialize(@id : String, @z : Int32 = 0)
      @entities = Array(Entity).new
      @systems = Array(System).new

      self << @camera
    end

    def initialize(@id : String, *entities_or_systems : Entity | System, @z : Int32 = 0)
      @entities = Array(Entity).new
      @systems = Array(System).new

      entities_or_systems.each do |e|
        if e.is_a? Entity
          @entities << e
        elsif e.is_a? System
          @systems << e
        end
      end

      reorder_entities()

      self << @camera
    end

    def reorder_entities
      @entities.sort_by! &.z
    end

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

      @entities.select! { |e| e.alive? }
    end

    def render(app, dt)
      @entities.each do |e|
        e.render_view(app, self, dt) if e.is_a? Objects::Camera
      end
    end

    # Adds an Entity to the Space
    def <<(entity : Entity)
      idx = 0
      @entities.each_with_index do |e, i|
        idx = i
        break if e.z > entity.z
      end
      @entities.insert(idx, entity)
    end

    # Adds multiple Entities to the Space
    def <<(*entities : Entity)
      entities.each { |e| self << e }
    end

    # Adds an System to the Space
    def <<(s : System)
      @systems << s
    end

    # Adds multiple Entities to the Space
    def <<(*systems : System)
      @systems.push entities
    end

    # For each Entity with the given component Type in the space, yields the entity and it's component
    def each_with(comp_type : T.class, &block : ((Entity, T) ->)) forall T
      @entities.each { |e|
        c = e[comp_type]?
        yield e, c if c
      }
    end

    # For each Entity with the given component Types in the space, yields the entity
    def each_with(comp_type : T.class, *other_comp_types : Component.class, &block : ((Entity, T) ->)) forall T
      @entities.each { |e|
        c = e[comp_type]?
        yield e, c if c && e.has? *other_comp_types
      }
    end

    # Get Entity with given id or raise
    def [](id : String) : Entity
      x = self[id]?
      if x.nil?
        Logger.fatal "No Entity with id '#{id}' found!"
      else
        return x
      end
    end

    # Get Entity with given id or nil
    def []?(id : String) : Entity | Nil
      @entities.find { |e| e.id == id }
    end
  end # End class Space
end   # End module Scar
