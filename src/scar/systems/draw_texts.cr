class Scar::Systems::DrawTexts < Scar::System
  def render(app, space, dt)
    space.each_with_transform Scar::Components::Text do |e, tr, text|
      text.sf.position = tr.pos.sf
      app.window.draw(text.sf)
    end
  end
end
