# This component is a wrapper around `SF::Text`
#
# Example usage:
# ```
# Assets.default_font = Assets.font "fonts/arial.ttf"
# title_text = Scar::Components::Text.new("Game Title")
# title = Scar::Entity.new("title", title_text)
# title.position = Vec.new(100, 100)
# ```
class Scar::Components::Text < Scar::Components::Drawable
  # Returns the `String` contents of this component
  getter text
  # Returns the `SF::Font` this component uses
  getter font
  # Returns the underlying `SF::Text`
  getter drawable : SF::Text

  # Creates a new text component with the given `String` content and font
  #
  # If no font is given, the component will try to use `Assets#default_font`.
  # This only works if `Assets#default_font` is set.
  def initialize(@text : String, font : SF::Font? = nil)
    font = font || Scar::Assets.default_font || raise "No font given and no default font for text components specified!"
    @drawable = SF::Text.new(@text, font)
  end

  # Replaces the components' `String` content with the provided new one
  def text=(new_text : String)
    @text = new_text
    @drawable.string = @text
  end

  # Sets the font this component should use
  def font=(new_font : SF::Font)
    @font = new_font
    @drawable.font = @font
  end
end
