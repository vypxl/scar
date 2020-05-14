# Use this to tag an entity as a camera. Needs a Z component.
class Scar::Components::Camera < Scar::Component
  property :x, :y, :width, :height

  # pos: Camera position on screen, wh: widht and height of the viewport
  def initialize(@x : Int32, @y : Int32, @width : Int32, @height : Int32)
  end
end
