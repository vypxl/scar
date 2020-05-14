module Scar
  # A Scene is a game state with multiple spaces
  class Scene
    property :spaces

    def initialize(@spaces : Array(Space))
    end

    def initialize
      @spaces = Array(Space).new
    end

    def initialize(*spaces : Space)
      @spaces = spaces.to_a
    end

    # Scene update logic
    def update(app, dt)
      @spaces.each do |s|
        s.update(app, dt)
      end
    end

    # Scene rendering logic
    def render(app, dt)
      @spaces.each do |s|
        s.render(app, dt)
      end
    end

    # Shortcut for `@spaces#push(*values : T)`
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
    end

    # Shortcut for @spaces#pop
    def pop
      @spaces.pop
      @spaces.sort_by! &.z
    end

    # Shortcut for @spaces#pop(&block)
    def pop(&block)
      @spaces.pop(block)
      @spaces.sort_by! &.z
    end

    def [](id : String) : Space
      x = self[id]?
      if x.nil?
        Logger.fatal "No Space with id '#{id}' found!"
      else
        return x
      end
    end

    def []?(id : String) : Space | Nil
      @spaces.find { |s| s.id == id }
    end
  end # End class Scene
end   # End module Scar
