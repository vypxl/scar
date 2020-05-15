require "./drawable.cr"

class Scar::Components::Sprite < Scar::Components::Drawable
  def initialize(@texture : SF::Texture, rect : SF::IntRect? = nil)
    @sf = SF::Sprite.new(@texture)
    @sf.texture_rect = rect if rect
  end

  def sf : SF::Drawable
    @sf
  end
end
