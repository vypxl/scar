module Scar
  # An entity is entirely defined by it's components.
  class Entity
    serializable({components: Array(Component)})

    def initialize
      @components = Array(Component).new
    end

    # Shortcut for adding a component
    def <<(c : Component)
      @components << c
      self
    end

    # Shortcut for adding multiple components
    def <<(*cs : Component)
      @components.push cs
      self
    end

    # Checks if Entity has a certain type of component
    def has(c : Class) : Bool
      @components.any? { |co| co.class == c }
    end

    # Checks if Entity has all the types of components specified
    def has(*cs : Class) : Bool
      cs.all do |c|
        @components.any? { |co| co.class == c }
      end
    end
  end
end # End module Scar
