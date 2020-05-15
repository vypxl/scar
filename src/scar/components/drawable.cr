# Components inheriting this must define a getter to a SFML Drawable
abstract class Scar::Components::Drawable < Scar::Component
  property :visible
  # Can be used to hide drawables from cameras
  @visible = true

  abstract def sf : SF::Drawable
end
