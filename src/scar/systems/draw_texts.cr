class Scar::Systems::DrawTexts < Scar::System
  def render(app, space, dt)
    space.each_with Scar::Components::Text do |e, text|
      text.sf.position = e.position.sf
      app.window.draw(text.sf)
    end
  end
end
