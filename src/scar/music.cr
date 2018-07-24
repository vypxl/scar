module Scar
  module Music
    extend self

    @@musics : Array(Assets::Music) = Array(Assets::Music).new

    # Pauses current music, pushes new music and starts playing it
    def play(asset_name : String)
      current.pause if current?
      @@musics << Assets[asset_name, Assets::Music]
      current.play
    end

    # Stops current music, removes it from the stack and continues previous music if any
    def pop_continue
      pop()
      current.play if current?
    end

    # Stops current music and removes it from the stack
    def pop
      current.stop
      @@musics.pop
    end

    def current
      @@musics.last
    end

    def current?
      @@musics.last?
    end
  end
end
