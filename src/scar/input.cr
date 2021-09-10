require "crsfml"

# TODO: make Input abstract and provide a default implementation, so that App's constructor argument makes sense OR remove that from App and make this a static module like Assets

# A simple class to be used in conjunction with `App`, which provides simple digital and analogue input bindings.
#
# You can also get creative with your input sources, you could e. g. implement an analogue input that changes with the current time.
#
# Example usage:
# ```
# input.bind_digital :jump { Scar::Input.sf_key :Space }
# input.bind_axis :time { Time.utc.millisecond / 1000 }
#
# input.axis :time # => 0.415 (example)
# ```
class Scar::Input
  @digital_bindings = Hash(Symbol, Array(-> Bool)).new
  @analog_bindings = Hash(Symbol, -> Float32).new

  # Returns true if the specified digital input is currently active
  def active?(which : Symbol)
    ret = false
    if @digital_bindings[which]?
      @digital_bindings[which].each { |check| ret = true if check.call }
    else
      Logger.warn "No digital input symbol '#{which}'"
    end
    ret
  end

  # Returns the value for the specified analogue input
  def axis(which : Symbol)
    ret = 0f32
    if @analog_bindings[which]?
      ret = @analog_bindings[which].call
    else
      Logger.warn "No axis input symbol '#{which}'"
    end
    ret
  end # End axis

  # Binds a `Symbol` to a digital input
  #
  # The check should return true if the input is currently active and false if not
  #
  # Example usage:
  # ```
  # input.bind_digital :jump { SF::Keyboard.key_pressed? SF::Keyboard::Space }
  # ```
  def bind_digital(which : Symbol, &block : -> Bool)
    @digital_bindings[which] = Array(-> Bool).new if !@digital_bindings[which]?
    @digital_bindings[which] << block
  end

  # Binds a `Symbol` to an analogue input
  #
  # Similar to `#bind_digital`, but here the check has to return a float instead of a boolean
  def bind_axis(which : Symbol, &block : -> Float32)
    @analog_bindings[which] = Array(-> Bool).new if !@analog_bindings[which]?
    @analog_bindings[which] = block
  end

  # Shortcut for digital inputs based on keys
  #
  # Example usage:
  # ```
  # input.bind_digital(:jump) { Scar::Input.key_pressed? :Space }
  # # This turns into
  # input.bind_digital(:jump) { SF::Keyboard.key_pressed? SF::Keyboard::{{which.id}} }
  # ```
  macro key_pressed?(which)
    SF::Keyboard.key_pressed? SF::Keyboard::{{which.id}}
  end
end
