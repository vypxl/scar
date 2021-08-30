module Scar
  # Object is the base class for OOP based Entities.
  # It has the same functions as a system: `init`, `update` and `render`, so all the functionality for an object can lie in one class.
  # You can still add components like with a normal entity though.
  # If you inherit from Object and include SF::Drawable, it will be drawn by cameras, so there is no need to implement the render method.
  abstract class Object < Scar::Entity
    property :initialized
    @initialized = false

    def init(app : App, space : Space); end

    def update(app : App, space : Space, dt); end

    def render(app : App, space : Space, dt); end
  end
end
