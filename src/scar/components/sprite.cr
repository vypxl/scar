require "./drawable.cr"

class Scar::Components::Sprite < Scar::Components::Drawable
  getter :sf

  def initialize(@texture : SF::Texture, rect : SF::IntRect? = nil)
    @sf = SF::Sprite.new(@texture)
    @sf.texture_rect = rect if rect
  end
end
