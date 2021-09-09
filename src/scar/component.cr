# Base class for Components
#
# Components add data to an `Entity`.
#
# Example usage:
# ```
# class MyComponent < Scar::Component
#   property name : String
#
#   def initialize(@name)
#   end
# end
#
# myEntity = Scar::Entity.new("my_entity", MyComponent.new("Bob"))
# ```
abstract class Scar::Component
end
