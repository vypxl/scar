require "./drawable.cr"

# This component is a wrapper around `SF::Sprite`
#
# Example usage:
# ```
# player_sprite = Scar::Components::Sprite.new(Assets.texture "textures/player.png")
# player = Scar::Entity.new("player", player_sprite)
# ```
class Scar::Components::Sprite < Scar::Components::Drawable
  # The `SF::Sprite` associated with this component
  property drawable : SF::Sprite

  # Creates a new sprite component. Specify *rect* if you need to set the sprites `texture_rect`
  def initialize(@texture : SF::Texture, rect : SF::IntRect? = nil)
    @drawable = SF::Sprite.new(@texture)
    @drawable.texture_rect = rect if rect
  end
end
