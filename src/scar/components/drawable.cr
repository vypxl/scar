# Components inheriting this must define a getter to a SFML Drawable
abstract class Scar::Components::Drawable < Scar::Component
  abstract def sf : SF::Drawable
end
