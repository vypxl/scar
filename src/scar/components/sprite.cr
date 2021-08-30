require "./drawable.cr"

class Scar::Components::Sprite < Scar::Components::Drawable
  getter drawable : SF::Sprite

  def initialize(@texture : SF::Texture, rect : SF::IntRect? = nil)
    @drawable = SF::Sprite.new(tex)
    @drawable.texture_rect = rect if rect
  end
end
