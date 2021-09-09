# This module provides simple methods to manage music playback.
#
# It utilizes a stack to enable simple continuation of previous music.
# This behaviour can be used to e. g. play pause music and continue playing
# the game music easily after unpausing the game.
#
# Example usage:
# ```
# Scar::Music.play "music/menu.ogg"
# # Game starts
# Scar::Music.play "music/overworld.ogg"
# # Player returns to menu
# Scar::Music.pop_continue
# ```
module Scar::Music
  extend self

  @@song_stack : Array(Assets::Music) = Array(Assets::Music).new

  # Pauses the current song, pushes the new song onto the song stack and starts playing it
  def play(asset_name : String)
    current.pause if current?
    @@song_stack << Assets[asset_name, Assets::Music]
    current.play
  end

  # Stops current song, removes it from the stack and continues playing the previous music (if present)
  def pop_continue
    pop()
    current.play if current?
  end

  # Stops current music and removes it from the stack
  def pop
    current.stop
    @@song_stack.pop
  end

  # Returns the song that is currently playing / on top of the song stack
  def current
    @@song_stack.last
  end

  # Returns the song that is currently playing / on top of the song stack, or nil if the song stack is empty
  def current?
    @@song_stack.last?
  end
end
