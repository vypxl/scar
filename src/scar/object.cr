module Scar
  # Object is the base class for OOP based Entities.
  # It has the same functions as a system: `init`, `update` and `render`, so all the functionality for an object can lie in one class.
  # You can still add components like with a normal entity though.
  abstract class Object < Scar::Entity
    property :initialized
    @initialized = false

    def init(app : App, space : Space); end

    def update(app : App, space : Space, dt); end

    def render(app : App, space : Space, dt); end
  end
end
