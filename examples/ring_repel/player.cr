include Scar

class FractionalCircle < SF::Shape
  getter :fraction

  def initialize(@radius : Float32, @fraction : Float32)
    super()
    @point_count = 64i32
    update()
  end

  def point_count : Int32
    @point_count + 1
  end

  def get_point(_index : Int) : SF::Vector2(Float32)
    index = _index.to_i

    return SF::Vector2.new(0f32, 0f32) if index == @point_count || @fraction == 0.0

    angle = (index * (Math::PI * 2 / (@point_count - 1)) * @fraction) + Math::PI / 4

    SF::Vector2.new(Math.sin(angle).to_f32 * @radius, Math.cos(angle).to_f32 * @radius)
  end

  def fraction=(val)
    @fraction = val.to_f32
    update()
  end
end

class PlayerComponent < Scar::Component
  include SF::Drawable
  getter :shapes, :hp

  @hp : UInt8

  def initialize
    @hp = 100

    @paddle = FractionalCircle.new(200, 0.25)
    @paddle.fill_color = SF::Color.new(100, 250, 50)

    @inner = SF::CircleShape.new(150, 64)
    @inner.origin = Vec.new(150, 150)
    @inner.fill_color = SF::Color::Black

    @inner_frac = FractionalCircle.new(150, 0)
    @inner_frac.fill_color = SF::Color::Red

    @body = SF::CircleShape.new(200, 64)
    @body.origin = Vec.new(200, 200)
    @body.fill_color = SF::Color::Blue

    @shapes = [@body, @paddle, @inner, @inner_frac]
  end

  def hp=(val)
    @hp = val
    @body.fill_color = SF::Color.new(255 - (@hp / 100 * 255).to_i, 0, (@hp / 100 * 255).to_i)
    @inner_frac.fraction = 1.0 - @hp / 100
  end

  def draw(target, states)
    shapes.each { |shape| target.draw(shape, states) }
  end
end

class PlayerSystem < Scar::System
  def initialize
    @hit_sound = SF::Sound.new(Assets.sound "ring_repel/hit.wav")
    @repel_sound = SF::Sound.new(Assets.sound "ring_repel/repel.wav")
  end

  def init(a, s)
    a.subscribe(BulletFactory::BulletHit) do
      player = s["player"][PlayerComponent]
      player.hp -= 1 if player.hp > 0
      @hit_sound.play

      if player.hp == 0
        a.game_over
      end
    end

    a.subscribe(BulletFactory::BulletRepelled) { @repel_sound.play }
  end

  def update(a, s, dt)
    s["player"].rotation = (SF::Mouse.get_position(a.window) - Vec.new(WIDTH / 2, HEIGHT / 2)).angle_deg
  end
end
