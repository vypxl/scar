# TODO entities should be able to have children

# An entity is any independent thing in your application, like a button, the player, an enemy, ...
#
# An entity contains `Component`s. They define the entity; An entity itself only has an id and transformational data (position, rotation, scale, z).
#
# Being a subclass of `SF::Transformable`, its `transform` is applied if this entity or any of its components is drawn.
#
# Example usage:
# ```
# player_sprite = Scar::Components::Sprite.new Assets.texture("textures/player.png")
# player = Scar::Entity.new("player", PlayerComponent.new, player_sprite, Scar::Vec.new(100, 100), z: 1)
# ```
class Scar::Entity < SF::Transformable
  # Used to specify the rendering order
  property z
  property :components
  getter :id

  @components : Array(Component)
  @id : String
  @alive = true

  @z : Int32 = 0

  def initialize(@id : String, @components : Array(Component), *, position : Vec? = nil, scale : Vec? = nil, rotation : Float32? = nil, z : Int32 = 0)
    super()
    self.position = position if !position.nil?
    self.scale = scale if !scale.nil?
    self.rotation = rotation if !rotation.nil?
    @z = z
  end

  def initialize(id : String, *, position : Vec? = nil, scale : Vec? = nil, rotation : Float32? = nil, z : Int32 = 0)
    initialize(id, Array(Component).new, position: position, scale: scale, rotation: rotation, z: z)
  end

  def initialize(id : String, *comps : Component, position : Vec? = nil, scale : Vec? = nil, rotation : Float32? = nil, z : Int32 = 0)
    initialize(id, Array(Component).new(comps.size) { |i| comps[i] }, position: position, scale: scale, rotation: rotation, z: z)
  end

  # Adds a component to this entity and returns self
  def <<(c : Component)
    @components << c
    self
  end

  # Adds multiple components to this entity and returns self
  def <<(*cs : Component)
    @components.push cs
    self
  end

  # Checks if this entity contains a component of the given type
  def has?(c : Component.class) : Bool
    @components.any? { |co| co.class <= c }
  end

  # Checks if this entity contains a component of every given type
  def has?(*cs : Component.class) : Bool
    cs.all? do |c|
      @components.any? { |co| co.class <= c }
    end
  end

  # :ditto:
  def has?(cs : Array(Component.class)) : Bool
    cs.all? do |c|
      @components.any? { |co| co.class <= c }
    end
  end

  # Returns this entities' component of given type
  def [](comp_type : T.class) : T forall T
    comp = components.find { |c| c.class <= comp_type }
    if comp.is_a? T
      comp
    else
      raise "Entity does not have component #{T.class}"
    end
  end

  # Returns this entities' component of given type or nil if it was not found
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
