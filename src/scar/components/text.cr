class Scar::Components::Text < Scar::Components::Drawable
  getter :text, :font, :sf

  def initialize(@text : String, @font : SF::Font)
    @sf = SF::Text.new(@text, @font)
  end

  def text=(new_text : String)
    @text = new_text
    @sf.string = @text
  end

  def font=(new_font : SF::Font)
    @font = new_font
    @sf.font = @font
  end
end
