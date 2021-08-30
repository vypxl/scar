# Components inheriting this must define a getter to a SFML Drawable
# This is just a convenience class, you can also just include
# Scar::Drawing::Drawable or SF::Drawable in your Component without
# inheriting from this.
abstract class Scar::Components::Drawable < Scar::Component
  include Scar::Drawable
end
