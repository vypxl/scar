module Scar
  # A Space holds Entities and Systems. Spaces should not interact with each other
  class Space
    serializable({entities: Array(Entity), systems: Array(System), z: Int32})

    def initialize(@z : Int32)
      @entities = Array(Entity).new
      @systems = Array(System).new
    end

    def update(app, dt)
      @systems.each { |s| s.update(app, self, dt) }
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
    def <<(system : System)
      @systems << system
    end

    # Adds multiple Entities to the Space
    def <<(*systems : System)
      @systems.push entities
    end

    # For each Entity with the given component Type in the space, yields the entity and it's component
    def each_with(comp_type : T.class, &block : ((Entity, T) ->))
      @entities.each { |e|
        c = e[comp_type]?
        yield e, c if c
      }
    end
  end # End class Space
end   # End module Scar
