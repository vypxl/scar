require "crsfml"

module Scar
  # An input handler.
  class Input
    # Initializes both digital and analog binding collections.
    def initialize
      @digital_bindings = Hash(Symbol, Array(-> Bool)).new
      @analog_bindings = Hash(Symbol, Array(-> Float32)).new
    end # End Initialize

    # Returns if the given input symbol is active.
    def active?(which : Symbol)
      ret = false
      if @digital_bindings[which]?
        @digital_bindings[which].each { |check| ret = true if check.call }
      else
        Logger.warn "No Input Symbol '#{which}'"
      end
      ret
    end # End active?

    # Returns the axis value for the given input symbol.
    def axis(which : Symbol)
      ret = false
      if @analog_bindings[which]?
        @analog_bindings[which].each { |check| ret = true if check.call }
      end
      ret
    end # End axis

    # Binds an input Symbol to a check.
    # A Check returns a boolean representation of the input.
    # For example:
    # ```
    # do
    #   SF::Keyboard.key_pressed? SF::Keyboard::Space
    # end
    # ```
    # could be a Check for the jump Symbol.
    def bind_digital(which : Symbol, &block : -> Bool)
      @digital_bindings[which] = Array(-> Bool).new if !@digital_bindings[which]?
      @digital_bindings[which] << block
    end

    # Binds an input Symbol to a axis Check.
    # Similar to #bind_digital, but here the Check needs to return a Float32
    # instead of a Bool.
    def bind_axis(which : Symbol, &block : -> Float32)
      @analog_bindings[which] = Array(-> Bool).new if !@analog_bindings[which]?
      @analog_bindings[which] << block
    end

    # Shortcut for digital checks
    # ```
    # SF::Keyboard.key_pressed? SF::Keyboard::{{which.id}}
    # ```
    macro sf_key(which)
      SF::Keyboard.key_pressed? SF::Keyboard::{{which.id}}
    end
  end # End Input
end   # End module Scar
