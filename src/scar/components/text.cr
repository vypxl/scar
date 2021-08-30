class Scar::Components::Text < Scar::Components::Drawable
  getter :text, :font, drawable : SF::Text

  def initialize(@text : String, font : SF::Font? = nil)
    font = font || Scar::Assets.default_font || raise "No font given and no default font for text components specified!"
    @drawable = SF::Text.new(@text, font)
  end

  def text=(new_text : String)
    @text = new_text
    @drawable.string = @text
  end

  def font=(new_font : SF::Font)
    @font = new_font
    @drawable.font = @font
  end
end
