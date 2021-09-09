# Base class for components that have some drawable attached to them, e. g. sprites
#
# Components inheriting from this class must define a getter to a SFML Drawable, see `Scar::Drawable`.
#
# Note that this is just a convenience class, you can also just include
# `Scar::Drawable` or `SF::Drawable` in your `Component` and it will be drawn regardless.
abstract class Scar::Components::Drawable < Scar::Component
  include Scar::Drawable
end
