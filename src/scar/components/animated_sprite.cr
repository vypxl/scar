require "./sprite.cr"

class Scar::Components::AnimatedSprite < Scar::Components::Sprite
  getter :sf, :size, :states, :state

  @spritesheet_size : Tuple(Int32, Int32)
  @delta : Float32

  # Spritesheet, size of each frame, hash of states with corresponding beginning-index, framecount and framerate.
  def initialize(@texture : SF::Texture, @size : Tuple(Int32, Int32), @states : Hash(String, Tuple(Int32, Int32, Int32)))
    @state = ""
    rect = SF::IntRect.new(0, 0, @size[0], @size[1])
    @sf = SF::Sprite.new(@texture)
    @sf.texture_rect = rect
    @current = 0
    tsize = ::Vec.from @texture.size
    @spritesheet_size = {(tsize.x / @size[0]).floor.to_i, (tsize.y / @size[1]).floor.to_i}
    @delta = 0f32
  end

  # Update time
  def update(dt)
    return unless @states[@state]?
    @delta += dt
    if @delta >= 1f32 / @states[@state][2]
      @delta = 0f32
      self.next
    end
  end

  # Next animation frame.
  def next
    return unless @states[@state]?
    @current += 1
    @current = 0 if @current >= @states[@state][1]
    idx = @current + @states[@state][0]
    x = @size[0] * (idx % @spritesheet_size[0])
    y = @size[1] * ((idx / @spritesheet_size[0]).floor)
    rect = SF::IntRect.new(x, y, @size[0], @size[1])
    @sf.texture_rect = rect
  end

  def state=(new_state : String)
    if @states[new_state]?
      @state = new_state
    else
      ::Logger.warn "Invalid animation state '#{new_state}'!"
      @state = ""
    end
  end
end
