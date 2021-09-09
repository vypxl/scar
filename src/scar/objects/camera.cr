# A camera takes care of calling render() functions and drawing drawables.
#
# A camera is essentially a wrapper around and `SF::View`.
# Its instance methods are delegated, so you can use them as normal instance methods.
# When drawing `Entity`s or `Object`s, their transforms are applied automatically.
#
# Each space has a default camera, so there is no need to use this class explicitly in your
# application, except if you need custom views. See the [CrSFML documentation](https://oprypin.github.io/crsfml/api/SF/View.html) for that.
class Scar::Objects::Camera < Scar::Object
  # Can be used to turn a camera off
  property enabled = true
  # If true, the camera will not use its `SF::View`
  property simple = true

  # The underlying `SF::View`
  property sf : SF::View

  # :nodoc:
  forward_missing_to @sf

  def initialize(id : String)
    super(id)
    @sf = SF::View.new
  end

  # This method is called by the render method of `Space`s
  #
  # It calls all render methods and draws all drawables onto the screen.
  def render_view(app, space, dt)
    return if !enabled

    # change view
    app.window.view = @sf if !@simple

    # call render functions
    space.systems.each(&.render(app, space, dt))

    space.entities.each do |e|
      # Draw drawable Objects
      if e.is_a? Scar::Object
        e.render(app, space, dt)
        draw_drawable(e, app.window) if e.is_a? SF::Drawable
      end

      # Draw drawable Components
      states = SF::RenderStates.new(e.transform)
      e.components.each { |c| draw_drawable(c, app.window, states) if c.is_a? SF::Drawable }
    end

    # reset view
    app.window.view = app.window.default_view if !@simple
  end

  private def draw_drawable(drawable : SF::Drawable, target, states = SF::RenderStates::Default)
    if drawable.is_a? Scar::Drawable
      return unless drawable.visible?
    end

    target.draw(drawable, states) if drawable.is_a? SF::Drawable
  end
end

# TODO remove simple
