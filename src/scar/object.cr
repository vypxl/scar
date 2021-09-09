module Scar
  # Base class for OOP based Entities
  #
  # An object has the same methods as a system: `#init`, `#update` and `#render`,
  # so all the behaviour and data can be in the same place.
  # You can still add components like with a normal entity though.
  #
  # You do not need to implement the `#render` method to draw something, you can also just use regular
  # drawable components or include `Scar::Drawable` (see `Drawable` documentation).
  abstract class Object < Scar::Entity
    property :initialized
    @initialized = false

    # For initialization (called once when this object is added to a space)
    def init(app : App, space : Space); end

    # For update logic (called on every frame)
    def update(app : App, space : Space, dt); end

    # For drawing logic (called on every frame *after* `update`)
    def render(app : App, space : Space, dt); end
  end
end
