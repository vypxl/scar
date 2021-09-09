# This module provides an easy way to use SFML drawables in your application.
#
# If this module is included in your `Component` or `Object`, any `Objects::Camera` in
# the space containing your entity will draw it to the screen.
#
# Use `#visible=`, `#texture`, `#shader` and `#blend_mode` to customize drawing.
# If you want to be able to transform your drawable component, include `SF::Transformable`.
#
# Instead of using this module, you can also include `SF::Drawable` and implement the `#draw` method yourself if you prefer.
#
# Example usage: See `Components::Sprite` ([source](https://github.com/vypxl/scar/blob/main/src/scar/components/sprite.cr)),
# `Components::Tilemap` ([source](https://github.com/vypxl/scar/blob/main/src/scar/components/tilemap.cr)) or other builtin components.
module Scar::Drawable
  include SF::Drawable
  # Can be used to disable drawing
  setter visible = true

  def visible?
    @visible
  end

  # Set this to use a blend mode while drawing
  property blend_mode : SF::BlendMode = SF::BlendMode::BlendAlpha
  # Set this to use a shader while drawing
  property shader : SF::Shader = SF::Shader.new
  # Set this to use a texture while drawing
  property texture : SF::Texture = SF::Texture.new

  # Should return the underlying `SF::Drawable`, e. g. `SF::Sprite` or `SF::Text`
  abstract def drawable : SF::Drawable

  # :nodoc:
  def draw(target, states)
    d = drawable
    t = states.transform
    t *= self.transform if self.is_a? SF::Transformable
    d.draw(target, SF::RenderStates.new(blend_mode, t, texture, shader)) if d.is_a? SF::Drawable
  end
end
