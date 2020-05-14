module Scar
  # A Space holds Entities and Systems. Spaces should not interact with each other
  class Space
    property :entities, :systems, :z, :id

    def initialize(@id : String, @entities : Array(Entity), @systems : Array(System), @z : Int32)
    end

    def initialize(@id : String, @z : Int32 = 0)
      @entities = Array(Entity).new
      @systems = Array(System).new
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
    end

    def update(app, dt)
      @systems.each do |s|
        if !s.inited
          s.init(app, self)
          s.inited = true
        end
        s.update(app, self, dt)
      end
      @entities.select! { |e| e.alive? }
    end

    def render(app, dt)
      @systems.each { |s| s.render(app, self, dt) }
    end

    # Adds an Entity to the Space
    def <<(entity : Entity)
      @entities << entity
    end

    # Adds multiple Entities to the Space
    def <<(*entities : Entity)
      @entities.push entities
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

    # For each Entity with the given component Type in the space, yields the entity and it's component
    def each_with_transform(comp_type : T.class, &block : ((Entity, Components::Transform, T) ->)) forall T
      @entities.each { |e|
        c = e[comp_type]?
        t = e[Components::Transform]?
        yield e, t, c if t && c
      }
    end

    # For each Entity with the given component Types in the space, yields the entity
    def each_with(comp_type : T.class, *other_comp_types : Component.class, &block : ((Entity, T) ->)) forall T
      @entities.each { |e|
        c = e[comp_type]?
        yield e, c if c && e.has? *other_comp_types
      }
    end

    # For each Entity with Transform component and the given component Types in the space, yields the entity, the Transform Component and the first specified Component
    def each_with_transform(comp_type : T.class, *other_comp_types : Component.class, &block : ((Entity, Components::Transform, T) ->)) forall T
      @entities.each { |e|
        c = e[comp_type]?
        t = e[Components::Transform]?
        yield e, t, c if t && c && e.has? *other_comp_types
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
