require "./player.cr"
require "./bullet.cr"

include Scar

class FpsSystem < Scar::System
  def update(app, space, dt)
    space["fps_display"][Components::Text].text = (1.0 / dt).floor.to_s
  end
end

class ScoreSystem < Scar::System
  def init(a, s)
    a.subscribe(BulletFactory::BulletRepelled) {
      a.score += 10
    }
  end

  def update(a, s, dt)
    s["score_display"][Components::Text].text = a.score.to_s
  end
end

def mk_main_scene
  fps = Entity.new("fps_display", Components::Text.new("0",), position: Vec.new(48, 48))
  score = Entity.new("score_display", Components::Text.new("-"), position: Vec.new(WIDTH - 100, 48))
  player = Entity.new("player", PlayerComponent.new, position: Vec.new(WIDTH / 2, HEIGHT / 2))

  Scene.new(
    Space.new("game",
      player, PlayerSystem.new, BulletFactory::BulletSystem.new,
      z: 0
    ),
    Space.new("ui",
      fps, score, FpsSystem.new, ScoreSystem.new,
      z: 1
    ),
  )
end
