class Scar::Systems::DrawSprites < Scar::System
  def render(app, space, dt)
    space.each_with Scar::Components::Sprite do |e, s|
      s.sf.position = e.position.sf
      app.window.draw(s.sf)
    end
  end
end
