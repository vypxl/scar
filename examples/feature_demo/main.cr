require "../scar"

WIDTH  = 1600
HEIGHT =  900

Signal::SEGV.reset
Signal::BUS.reset

class PlayerComponent < Scar::Component
end

class PlayerSystem < Scar::System
  include Scar

  @jump_key = 0
  @can_jump = 2
  @jump1 : Tween? = nil
  @jump1_h = 0f32

  @jump_sound = SF::Sound.new(Assets.sound "jump.wav")

  SPEED       = 800
  JUMP_HEIGHT = 500
  JUMP_TIME   = 0.8
  GROUND      = HEIGHT - 128

  def update(app, space, dt)
    player = space["player"]
    spr = player[Components::AnimatedSprite]

    movement = Vec.new
    movement.x += 1 if Input.active? :Right
    movement.x -= 1 if Input.active? :Left
    running = Input.active? :Run
    movement *= 1.8 if running
    player.position += movement * SPEED * dt

    spr.state = movement == 0 ? "idle" : (running ? "run" : "walk") unless spr.state == "jump"

    x = player.position.x
    x = WIDTH.to_f32 if player.position.x < 0
    x = 0f32 if player.position.x > WIDTH
    player.position = player.position.new_x(x)
    @can_jump = 2 if player.position.y == GROUND

    if Input.active? :Jump
      if @jump_key == 0
        @jump_key = 1
      else
        @jump_key = 2
      end
    else
      @jump_key = 0
    end

    if @can_jump > 0 && @jump_key == 1
      @can_jump -= 1
      spr.state = "jump"
      @jump_sound.play
      if @can_jump == 1
        @jump1 = app.tween(Tween.new JUMP_TIME/2, Easing::EaseOutQuad.new, ->(t : Tween) {
          player.position = player.position.new_y(GROUND - t.fraction * JUMP_HEIGHT)
        }, ->(t : Tween) {
          @jump1 = app.tween(Tween.new JUMP_TIME/2, Easing::EaseInQuad.new, ->(t : Tween) {
          player.position = player.position.new_y(GROUND - (JUMP_HEIGHT - t.fraction * JUMP_HEIGHT))
        }, ->(t : Tween) {
            @can_jump = 2
            @jump1 = nil
            spr.state = "idle"
            nil
          })
          nil
        })
      else
        j = @jump1
        if j
          j.paused = true
          j.abort
        end
        @jump1_h = GROUND - player.position.y
        app.tween(Tween.new JUMP_TIME/2, Easing::EaseOutQuad.new, ->(t : Tween) {
          player.position = player.position.new_y(GROUND - (@jump1_h + t.fraction * JUMP_HEIGHT))
        }, ->(t : Tween) {
          app.tween(Tween.new JUMP_TIME/2, Easing::EaseInQuad.new, ->(t : Tween) {
            player.position = player.position.new_y(GROUND - (@jump1_h + JUMP_HEIGHT - t.fraction * (@jump1_h + JUMP_HEIGHT)))
          }, ->(t : Tween) {
            @can_jump = 2
            @jump1 = nil
            spr.state = "idle"
            nil
          })
          nil
        })
      end
    end
  end
end

class FPSSystem < Scar::System
  include Scar

  def update(app, space, dt)
    space["fps_counter"][Components::Text].text = "FPS: #{(1 / dt).round 1}"
  end
end

class ExitHandling < Scar::System
  include Scar

  def update(a, s, dt)
    a.broadcast(Event::Closed.new) if Input.active?(:Closed)
    s["behind_player"].destroy if Input.active?(:Kill) && s["behind_player"]?
  end
end

class FeatureDemo < Scar::App
  include Scar

  def init
    @window.position = SF.vector2i(window.position.x + 100, 100)
    @window.framerate_limit = 120

    Input.bind_digital(:Closed) { Input.key_pressed?(:Escape) }
    Input.bind_digital(:Closed) { Input.key_pressed?(:Q) }
    Input.bind_digital(:Closed) { SF::Joystick.button_pressed?(0, 1) }

    Input.bind_digital(:Left) { Input.key_pressed?(:Left) }
    Input.bind_digital(:Right) { Input.key_pressed?(:Right) }
    Input.bind_digital(:Left) { Input.key_pressed?(:A) }
    Input.bind_digital(:Right) { Input.key_pressed?(:D) }
    Input.bind_digital(:Run) { Input.key_pressed?(:LShift) }
    Input.bind_digital(:Jump) { Input.key_pressed?(:Space) }

    Input.bind_digital(:Left) { SF::Joystick.get_axis_position(0, SF::Joystick::X) < 0 }
    Input.bind_digital(:Right) { SF::Joystick.get_axis_position(0, SF::Joystick::X) > 0 }
    Input.bind_digital(:Run) { SF::Joystick.button_pressed?(0, 2) }
    Input.bind_digital(:Jump) { SF::Joystick.button_pressed?(0, 0) }

    Input.bind_digital(:Kill) { Input.key_pressed?(:K) }

    subscribe(Event::Closed) { Logger.debug "exit"; exit() }

    Assets.use "assets"
    # Assets.cache_zipfile "assets.zip"
    Assets.load_all
    Assets.default_font = Assets.font "OpenSans-Regular.ttf"

    self << Scene.new(
      Space.new("ui",
        FPSSystem.new,
        z: 2
      ),
      Space.new("main",
        ExitHandling.new,
        PlayerSystem.new,
        Systems::AnimateSprites.new,
        z: 1
      ),
      Space.new("background", z: 0)
    )

    # Background
    background_tex = Assets.texture "nested/background.png"
    scene["background"] << Entity.new("background",
      Components::Sprite.new(background_tex),
      scale: Vec.new(WIDTH, HEIGHT) / background_tex.size
    )

    # Player
    anspr = Components::AnimatedSprite.new(
      Assets.texture("spritesheet.png"),
      {128, 128},
      {"idle" => {0, 4, 4}, "walk" => {0, 4, 8}, "run" => {0, 4, 16}, "jump" => {8, 8, 16}}
    )
    anspr.state = "idle"

    player = Entity.new("player",
      anspr,
      PlayerComponent.new,
      position: Vec.new(500, PlayerSystem::GROUND),
      z: 1
    )
    scene["main"] << player
    scene["main"] << Entity.new("behind_player",
      Components::Sprite.new(Assets.texture("nested/background.png"), SF::Rect.new(0, 0, 128, 128)),
      position: Vec.new(200, PlayerSystem::GROUND),
      z: 0
    )

    # Sample text
    scene["ui"] << Entity.new("text",
      Components::Text.new(Assets.text "text.txt"),
      position: Vec.new(400, 100)
    )

    # FPS counter
    scene["ui"] << Entity.new("fps_counter",
      Components::Text.new("FPS: 0"),
      position: Vec.new(10, 10)
    )

    mov_dir = 1;

    tween Tween.bind_value(1, Easing::EaseInOutQuint.new, scene["ui"]["fps_counter"].position, "Vec.new 10, 800 * Math.sin Math::PI *")
      .then { |t|
        mov_dir *= -1
        t.reset
      }


    cam = scene["ui"].camera
    cam.reset(SF::Rect(Float32).new(0, 0, 600, 600))
    cam.rotate(90)
    cam.viewport = SF::Rect(Float32).new(0.1, 0.1, 0.6, 0.6)

    act Actions::Timed.new(5, ->{ Logger.info "hi after 5 seconds" })

    Music.play("music.ogg")
    Music.current.loop = true
    Music.current.volume = 30
  end

  def update(dt)
  end

  def render(dt)
    @window.clear(SF::Color::Black)
  end
end

window = SF::RenderWindow.new(SF::VideoMode.new(WIDTH, HEIGHT), "Test", SF::Style::Close)

app = FeatureDemo.new(window)
app.run
