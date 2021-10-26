require "../scar"
require "./main_scene.cr"

WIDTH = 900
HEIGHT = 900

class StartSystem < Scar::System
  def update(a, s, dt)
    a << mk_main_scene() if Input.active? :Start
  end
end

class RingRepel < Scar::App
  include Scar

  property :score
  @score : Int64 = 0
  @high_score : Int64 = 0

  def init
    @window.framerate_limit = 120

    Input.bind_digital(:Closed) { Input.key_pressed?(:Escape) }
    Input.bind_digital(:Closed) { Input.key_pressed?(:Q) }
    Input.bind_digital(:Closed) { SF::Joystick.button_pressed?(0, 1) }
    Input.bind_digital(:Start)  { Input.key_pressed?(:Space) }

    Assets.use "assets"
    Assets.load_all
    Assets.default_font = Assets.font "OpenSans-Regular.ttf"

    subscribe(Event::Closed) { exit(0) }

    @score = 0

    self << mk_menu_scene()
    Music.play "ring_repel/music.ogg"
    Music.current.loop = true
    Music.current.volume = 50
  end

  def update(dt)
    broadcast(Event::Closed.new) if Input.active?(:Closed)
  end

  def render(dt)
    @window.clear(SF::Color::Black)
  end

  def game_over
    pop()
    if @score > @high_score
      @high_score = @score
      scene.spaces[0]["score"][Components::Text].text = "Score: #{@score} | Highscore: #{@high_score}"
    end
  end

  def mk_menu_scene()
    sc = Scene.new
    sp = Space.new("ui")
    sc << sp
    sp << Entity.new("txt", Components::Text.new("Press space to start!"), position: Vec.new(48, 96))
    sp << Entity.new("score", Components::Text.new("Score: - | Highscore: -"), position: Vec.new(48, 48))
    sp << StartSystem.new
    sc
  end
end

settings = SF::ContextSettings.new
settings.antialiasing_level = 4
window = SF::RenderWindow.new(SF::VideoMode.new(WIDTH, HEIGHT), "Ring Repel", SF::Style::Close, settings)
desktop_mode = SF::VideoMode.desktop_mode
window.position = SF.vector2i(desktop_mode.width - WIDTH - (desktop_mode.width // 10).to_i, desktop_mode.height // 10)
app = RingRepel.new(window)
app.run
