# A camera takes care of calling render() functions and drawing drawables.
# A camera is essentially a wrapper around and `SF::View`. Its instance methods are delegated, so you can use them as normal instance methods.
class Scar::Objects::Camera < Scar::Object
  property :sf, :enabled, :simple

  # Can be used to turn a camera off
  @enabled = true
  # If true, the camera will not use its `SF::View`
  @simple = true
  @sf : SF::View

  forward_missing_to @sf

  def initialize(id : String)
    super(id)
    @sf = SF::View.new
  end

  def render_view(app, space, dt)
    return if !enabled

    # change view
    app.window.view = @sf if !@simple

    # call render functions
    space.systems.each { |s| s.render(app, space, dt) }
    space.entities.each do |e|
      if e.is_a? Object
        e.render(app, space, dt)
      end
    end

    # draw drawables
    space.each_with(Scar::Components::Drawable) do |entity, drawable|
      sf_drawable = drawable.sf
      if sf_drawable.is_a? SF::Transformable
        sf_drawable.position = entity.position
        sf_drawable.scale = entity.scale
        sf_drawable.rotation = entity.rotation
      end
      app.window.draw(sf_drawable) if drawable.visible && sf_drawable.is_a? SF::Drawable
    end

    # reset view
    app.window.view = app.window.default_view if !@simple
  end
end
