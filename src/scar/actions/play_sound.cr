module Scar::Actions
  class PlaySound < Scar::Action
    def initialize(@sound : Scar::Assets::Sound)
    end

    def on_start
      @sound.play
    end

    def completed?(dt)
      @sound.status.stopped?
    end
  end
end
