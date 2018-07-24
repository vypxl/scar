class Scar::Components::Transform < Scar::Component
  property :pos

  def initialize(@pos : Vec)
  end

  def initialize(x, y)
    initialize(Vec.new(x, y))
  end
end
