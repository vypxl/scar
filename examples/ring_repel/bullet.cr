module BulletFactory
  include Scar

  struct BulletRepelled < Scar::Event::Event; end

  struct BulletHit < Scar::Event::Event; end

  class BulletComponent < Scar::Components::Drawable
    getter :color
    property :velocity, :speed, :bounces
    property drawable : SF::Drawable
    RADIUS = 16

    @velocity : Vec
    @speed : Float32
    @drawable : SF::CircleShape

    def initialize(_spawn, bounces : Int32)
      @color = SF::Color.new(Random.rand(256), Random.rand(256), Random.rand(256))
      @drawable = SF::CircleShape.new(RADIUS)
      @drawable.fill_color = @color
      @drawable.origin = {RADIUS, RADIUS}
      @speed = Random.rand(200..350).to_f32
      @bounces = bounces
      @velocity = (Vec.new(WIDTH / 2, HEIGHT / 2) - _spawn).unit * @speed
    end
  end

  class BulletSystem < Scar::System
    @elapsed = 0.0

    def update(a, s, dt)
      freq = a.score / 500.0 + 0.5
      @elapsed += dt
      if @elapsed > 1.0 / freq
        s << BulletFactory.mk_bullet((a.score / 500).floor.to_i)
        @elapsed = 0
      end

      player = s["player"]
      player_rot = player.rotation

      middle = Vec.new(WIDTH / 2, HEIGHT / 2)

      # move, destroy and bounce bullets
      s.each_with BulletComponent do |e, blt|
        e.position += blt.velocity * dt

        ang = (middle - e.position).angle_deg

        # bounce or destroy if out of bounds
        unless SF::Rect.new(-100, -100, WIDTH + 100, HEIGHT + 100).contains?(e.position)
          if blt.bounces > 0
            blt.velocity = Vec.from_polar_deg(ang + (Random.rand - 0.5) * 30, blt.speed)
            blt.bounces -= 1
          else
            e.destroy
          end
        end

        # convert to absolute angle to test against player (-180..180 -> 0..360)
        ang = ang + 180

        # collide with player
        if e.position.dist(middle) - BulletComponent::RADIUS - 3 < 200
          if (180 - ((ang - player_rot).abs - 180).abs).abs < 45
            blt.velocity *= -1
            a.broadcast BulletRepelled.new
          else
            a.broadcast BulletHit.new
            e.destroy
          end
        end
      end
    end
  end

  SPAWNS = [
    Vec.new(0, 0), Vec.new(0.5, 0), Vec.new(1, 0), Vec.new(1, 0.5), Vec.new(1, 1), Vec.new(0.5, 1), Vec.new(0, 1), Vec.new(0, 0.5),
  ].map { |v| v * Vec.new(WIDTH, HEIGHT) }
  @@bullet_id = 0u32

  def self.mk_bullet(bounces)
    _spawn = SPAWNS[Random.rand(SPAWNS.size)].dup
    e = Entity.new("bullet_#{@@bullet_id}", BulletComponent.new(_spawn, bounces), position: _spawn)
    @@bullet_id += 1
    e
  end
end
