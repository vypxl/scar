module Scar
  # A Scene is a game state with multiple spaces
  class Scene
    getter :spaces

    def initialize
      @spaces = Array(Space).new
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

    # Shortcut for @spaces#<<
    def <<(space : Space)
      @spaces << space
      @spaces.sort_by! &.z
    end

    # Shortcut for @spaces#push(*values : T)
    def <<(*spaces : Space)
      @spaces.push spaces
      @spaces.sort_by! &.z
    end

    # Shortcut for @spaces#pop
    def pop(&block)
      @spaces.pop(block)
      @spaces.sort_by! &.z
    end
  end # End class Scene
end   # End module Scar
