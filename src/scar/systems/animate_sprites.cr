class Scar::Systems::AnimateSprites < Scar::System
  def render(app, space, dt)
    space.each_with(Scar::Components::AnimatedSprite) do |e, animated_sprite|
      animated_sprite.update(dt)
    end
  end
end
