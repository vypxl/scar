# Base class for Systems
#
# Systems define behaviours in the application
# e. g. player movement, ai updates, ..
#
# Example usage:
# ```
# class MySystem < Scar::System
#   def init(app, space)
#     puts "MySystem initialized!"
#   end
#
#   def update(app, space, dt)
#     # Move the player entity
#     space["player"].move(Vec.new(10, 0) * dt)
#   end
#
#   def render(app, space, dt)
#     puts "Executing custom rendering logic..."
#   end
# end
# ```
abstract class Scar::System
  # This property keeps track of wether `#init` has been called
  property initialized = false

  # Override this for one-time initialization
  #
  # This method is called by the space containing this System on the first frame after it was added.
  def init(app : App, space : Space); end

  # Override this for any behaviour you want in you application
  #
  # This method is called by the space containing this System on every frame before any rendering occurs.
  def update(app : App, space : Space, dt); end

  # Override this for custom rendering logic
  #
  # This method is called by the space containing this System on every frame before any rendering occurs.
  def render(app : App, space : Space, dt); end
end

# TODO: systems should just be functions, not classes. This means that #init and #render will not be available anymore, but they are not needed anyway. #init can be replaced by actions and #render should not be implemented manually
