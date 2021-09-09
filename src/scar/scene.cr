module Scar
  # A Scene is a container for one independent state of your application, like title screen, in-game, pause menu, ...
  #
  # A Scene contains `Space`s.
  #
  # Scenes live on an `App`'s scene stack, while only the topmost scene is updated and rendered. This means that you can
  # e. g. push your pause scene onto the stack and pop it off later and your ingame scene will get paused automatically.
  # You could also implement a system that updates and/or renders other scenes, so that your pause scene shows your game
  # in the background.
  #
  # Example usage:
  # ```
  # sc = Scene.new
  # sc << Space.new("ui", ...)
  # sc << Space.new("game", ...)
  # app << sc
  # ```
  class Scene
    getter :spaces

    def initialize(@spaces : Array(Space))
      @spaces.sort_by! &.z
    end

    def initialize
      @spaces = Array(Space).new
    end

    def initialize(*spaces : Space)
      @spaces = spaces.to_a.sort_by &.z
    end

    # Sorts the spaces in the scene by their z value
    def reorder_spaces
      @spaces.sort_by! &.z
    end

    # :nodoc:
    def update(app, dt)
      @spaces.each do |s|
        s.update(app, dt)
      end
    end

    # :nodoc:
    def render(app, dt)
      @spaces.each do |s|
        s.render(app, dt)
      end
    end

    # Adds one or more spaces to the scene and returns self
    def <<(*spaces : Space)
      ids = @spaces.map &.id
      spaces.each do |space|
        if ids.includes? space.id
          Logger.fatal "Duplicate Space id '#{space.id}'"
        else
          @spaces << space
        end
      end
      @spaces.sort_by! &.z
      self
    end

    # Returns the space with the given id
    def [](id : String) : Space
      x = self[id]?
      if x.nil?
        Logger.fatal "No Space with id '#{id}' found!"
      else
        x
      end
    end

    # Returns the space with the given id or nil when it is not found
    def []?(id : String) : Space | Nil
      @spaces.find { |s| s.id == id }
    end
  end # End class Scene
end   # End module Scar
