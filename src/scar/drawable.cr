# Include and implement #drawable to display components or objects onto the screen
# You can use `visible`, `texture`, `shader` and `blend_mode` to customize drawing.
# If you want to be able to transform a drawable, include SF::Transformable
#
# Instead of using this Module, you can also include SF::Drawable and implement the #draw method if you prefer
module Scar::Drawable
  include SF::Drawable
  # Can be used to disable drawing
  setter visible = true

  def visible?
    @visible
  end

  property blend_mode : SF::BlendMode = SF::BlendMode::BlendAlpha
  property shader : SF::Shader = SF::Shader.new
  property texture : SF::Texture = SF::Texture.new

  abstract def drawable : SF::Drawable

  def draw(target, states)
    d = drawable
    t = states.transform
    t *= self.transform if self.is_a? SF::Transformable
    d.draw(target, SF::RenderStates.new(blend_mode, t, texture, shader)) if d.is_a? SF::Drawable
  end
end
