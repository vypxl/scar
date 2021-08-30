module Scar
  # TODO entities should be able to have children

  # An entity is entirely defined by its components.
  # Being a subclass of SF::Transformable, its `transform` is applied if this entity or any of its components is drawn
  class Entity < SF::Transformable
    property :components, :z
    getter :id

    @components : Array(Component)
    @id : String
    @alive = true

    @z : Int32 = 0

    def initialize(@id : String, @components : Array(Component), *, position : Vec? = nil, scale : Vec? = nil, rotation : Float32? = nil, z : Int32 = 0)
      super()
      @position = position if !position.nil?
      @scale = scale if !scale.nil?
      @rotation = rotation if !rotation.nil?
      @z = z
    end

    def initialize(id : String, *, position : Vec? = nil, scale : Vec? = nil, rotation : Float32? = nil, z : Int32 = 0)
      initialize(id, Array(Component).new, position: position, scale: scale, rotation: rotation, z: z)
    end

    def initialize(id : String, *comps : Component, position : Vec? = nil, scale : Vec? = nil, rotation : Float32? = nil, z : Int32 = 0)
      initialize(id, Array(Component).new(comps.size) { |i| comps[i] }, position: position, scale: scale, rotation: rotation, z: z)
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
      @components.any? { |co| co.class <= c }
    end

    # Checks if Entity has all the types of components specified.
    def has?(*cs : Component.class) : Bool
      cs.all? do |c|
        @components.any? { |co| co.class <= c }
      end
    end

    # Checks if Entity has all the types of components specified.
    def has?(cs : Array(Component.class)) : Bool
      cs.all? do |c|
        @components.any? { |co| co.class <= c }
      end
    end

    # Returns this entities' component of given type or raises.
    def [](comp_type : T.class) : T forall T
      comp = components.find { |c| c.class <= comp_type }
      if comp.is_a? T
        comp
      else
        raise "Entity does not have component #{T.class}"
      end
    end

    # Returns this entities' component of given type or nil.
    def []?(comp_type : T.class) : (T | Nil) forall T
      comp = components.find { |c| c.class <= comp_type }
      if comp.is_a? T
        comp
      else
        nil
      end
    end

    # Marks this entity for removal
    def destroy
      @alive = false
    end

    # Getter for alive
    def alive?
      @alive
    end
  end
end # End module Scar
