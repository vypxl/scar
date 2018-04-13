module Scar
  # An entity is entirely defined by it's components.
  class Entity
    serializable({components: Array(Component)})

    def initialize
      @components = Array(Component).new
    end

    # Shortcut for adding a component.
    def <<(c : Component)
      @components << c
      self
    end

    # Shortcut for adding multiple components.
    def <<(*cs : Component)
      @components.push cs
      self
    end

    # Checks if Entity has a certain type of component.
    def has?(c : Component.class) : Bool
      @components.any? { |co| co.class == c }
    end

    # Checks if Entity has all the types of components specified.
    def has?(*cs : Component.class) : Bool
      cs.all do |c|
        @components.any? { |co| co.class == c }
      end
    end

    # Returns this entities' component of given type or raises.
    def [](comp_type : T.class) : T forall T
      comp = components.find { |c| c.class == comp_type }
      if comp.is_a? T
        comp
      else
        raise "Entity does not have component #{T.class}"
      end
    end

    # Returns this entities' component of given type or nil.
    def []?(comp_type : T.class) : (T | Nil) forall T
      comp = components.find { |c| c.class == comp_type }
      if comp.is_a? T
        comp
      else
        nil
      end
    end
  end
end # End module Scar
