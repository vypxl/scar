# Base class for one-off actions
#
# Sample usage:
#
# ```
# class MyAction < Scar::Action
#   def completed?(dt)
#     true # This action completes instantly
#   end
#
#   def on_start
#     puts "MyAction start!"
#   end
#
#   def on_end
#     puts "MyAction end!"
#   end
# end
#
# # Somewhere in your application
# app.act MyAction.new
#
# # Output:
# # MyAction start!
# # MyAction end!
abstract class Scar::Action
  # Should return true as soon as the action has finished
  #
  # This method is called on each frame with the delta time as an argument.
  # `#on_end` is called after this method returns true.
  # By default, an action completes immediately.
  def completed?(dt : Float32)
    true
  end

  # This method is called immediately after the action was activated via `Scar::App#act`
  def on_start; end

  # This method is called immediately after `#completed?` returned true on a frame
  def on_end; end
end
