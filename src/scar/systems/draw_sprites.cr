class Scar::Systems::DrawSprites < Scar::System
  def render(app, space, dt)
    space.each_with_transform Scar::Components::Sprite do |e, t, s|
      s.sf.position = t.pos.sf
      app.window.draw(s.sf)
    end
  end
end
