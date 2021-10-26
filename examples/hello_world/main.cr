require "../scar"

class HelloWorld < Scar::App
  def init
    Scar::Assets.use "assets"
    Scar::Assets.load "OpenSans-Regular.ttf"
    Scar::Assets.default_font = Scar::Assets.font "OpenSans-Regular.ttf"

    self << Scar::Scene.new

    text_component = Scar::Components::Text.new "Hello World"

    space = Scar::Space.new "Main space"
    space << Scar::Entity.new "text", text_component, position: Scar::Vec.new(32, 16)

    scene << space
  end

  def update(dt)
  end

  def render(dt)
    @window.clear(SF::Color::Black)
  end
end

window = SF::RenderWindow.new SF::VideoMode.new(320, 180), "Hello World", SF::Style::Close
HelloWorld.new(window).run
