class Scar::Components::Transform < Scar::Component
  property :pos, :scale, :rotation

  def initialize(@pos : Vec, @scale : Vec = Vec.new(1, 1), @rotation : Float32 = 0f32)
  end
end
