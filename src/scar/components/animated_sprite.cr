require "./sprite.cr"

# This component is a more advanced wrapper around `SF::Sprite`.
#
# It supports multi-state animation based on a spritesheet. It is supposed to be used in conjunction with `Systems::AnimateSprites`.
#
# The spritesheet must such a layout that each animation state can be described as an index range
# inside the spritesheet. This means that each frame must have the same pixel size and all frames
# of an animation state must appear in sequence in the spritesheet (right-down order).
# See [Scar examples](https://github.com/vypxl/scar_examples) for real-world examples.
#
# Example usage:
# ```
# # The example spritesheet could be lay out like this:
# #
# # AAAABB
# # BBCCCC
# #
# sprite = Scar::Components::AnimatedSprite.new(
#   Assets.texture("textures/spritesheet.png"), # Get the spritesheet from the asset manager
#   {32, 32},                                   # Each frame has a size of 32x32 pixels
#   {
#   "A" => {0, 4, 2}, # Start index: 0, framecount: 4, fps: 2
#   "B" => {4, 4, 5}, # Start index: 4, framecount: 4, fps: 5
#   "C" => {8, 4, 8}, # Start index: 8, framecount: 4, fps: 8
# }
# )
#
# sprite.state = "A" # Necessary, there is no default animation state
# ```
#
# Note that animation states can share frames, but only if both states' frames remain in sequence.
#
# Example:
# > Spritesheet layout: `AASSBB`.
#
# > Animation states `A` and `B` share the frames `S` in the middle.
#
# > State `A` uses the frames 0-3 and state `B` uses the frames 2-5.
class Scar::Components::AnimatedSprite < Scar::Components::Sprite
  # Returns the frame size in pixels
  getter size
  # Returns the hash of animation states
  getter states
  # Returns the name of the current animation state
  getter state

  @spritesheet_size : Tuple(Int32, Int32)
  @delta : Float32

  # Creates a new animated sprite
  #
  # Parameters:
  # - *texture*: Source spritesheet
  # - *size*: size of a frame in pixels {width, height}
  # - *states*: list of animation states {start-index, framecount, framerate} (see overview for an example)
  def initialize(@texture : SF::Texture, @size : Tuple(Int32, Int32), @states : Hash(String, Tuple(Int32, Int32, Int32)))
    @state = ""
    rect = SF::IntRect.new(0, 0, @size[0], @size[1])
    @drawable = SF::Sprite.new(@texture)
    @drawable.texture_rect = rect
    @current = 0
    tsize = Vec.from @texture.size
    @spritesheet_size = {(tsize.x / @size[0]).floor.to_i, (tsize.y / @size[1]).floor.to_i}
    @delta = 0f32
  end

  # Advances the current animation by the given delta time
  def update(dt)
    return unless @states[@state]?
    @delta += dt
    if @delta >= 1f32 / @states[@state][2]
      @delta = 0f32
      self.next
    end
  end

  # Advances the current animation to its next frame
  def next
    return unless @states[@state]?
    @current += 1
    @current = 0 if @current >= @states[@state][1]
    idx = @current + @states[@state][0]
    x = @size[0] * (idx % @spritesheet_size[0])
    y = @size[1] * ((idx / @spritesheet_size[0]).to_i)
    rect = SF::IntRect.new(x, y, @size[0], @size[1])
    @drawable.texture_rect = rect
  end

  # Sets the current animation state
  #
  # Takes the name of an animation state specified in the *states* parameter of the constructor
  #
  # Example usage:
  # ```
  # an_sprite = Scar::Components::AnimatedSprite.new(... "idle" => {...} ...)
  # an_sprite.state = "idle"
  # ```
  def state=(new_state : String)
    if @states[new_state]?
      @state = new_state
    else
      Logger.warn "Invalid animation state '#{new_state}'!"
      @state = ""
    end
  end
end

# TODO add 0 fps mode, this way the animation will not be advanced automatically.
