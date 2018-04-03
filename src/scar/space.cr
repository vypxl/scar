
module Scar
  # A Space holds Entities and Systems. Spaces should not interact with each other
  class Space
    getter :z

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
  end # End class Space
end # End module Scar
