# This system is required in order for `Components::AnimatedSprite` to work properly
class Scar::Systems::AnimateSprites < Scar::System
  # Updates all animated sprite components in the space
  def render(app, space, dt)
    space.each_with(Scar::Components::AnimatedSprite) do |e, animated_sprite|
      animated_sprite.update(dt)
    end
  end
end
