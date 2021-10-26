# This module aims to be a simple interface for storing
# basic key-value configuration like keybindings, window settings, ..
#
# You can store everything that can be represented by `YAML::Any`.
#
# Example usage:
# ```
# # At toplevel
# Scar::Config.set_defaults({
#   int: 7331,
#   str: "hello world",
#   arr: [1, 3, 3, 7],
# })
#
# puts Config[:int] # => 7331
#
# Scar::Config[:str] = "lol"
# puts Config[:str] # => lol
#
# Scar::Util.dir = "config-examle" # don't forget to specify a data directory for your files!
# Scar::Config.save                # using default filename "config.yml"
#
# Scar::Config.reset(:str)
# puts Config[:str] # => hello world
#
# # By loading the saved config from before, the `:str` entry is "lol" again
# Scar::Config.load "config.yml"
# puts Scar::Config[:str] # => lol
# ```
module Scar::Config
  extend self

  @@data : Hash(String, YAML::Any) = Hash(String, YAML::Any).new
  @@defaults : Hash(String, YAML::Any) = Hash(String, YAML::Any).new

  # Resets the value of a configuration entry to it's standard (see `Config#define_defaults`)
  def reset(key)
    @@data[key.to_s] = convert(@@defaults[key.to_s]?)
  end

  # Defines standard values for configuration entries to fall back to.
  #
  # Specify the defaults as a `NamedTuple` of format `{entry name}: {value}`.
  #
  # Example:
  # ```
  # Scar::Config.define_defaults({
  #   str: "hello world",
  #   arr: [1, 3, 3, 7],
  # })
  # ```
  macro set_defaults(defaults)
    module Scar::Config
      @@defaults = Hash(String, YAML::Any) {
        {% for k, v, i in defaults %}"{{k.id}}" => convert({{v}}){% if i < defaults.size - 1 %},{% end %}
        {% end %}
      }
      load_defaults()
    end
  end

  # Resets all configuration entries to their standard value
  def load_defaults
    @@data = Hash(String, YAML::Any).new
    @@defaults.each_key { |key| @@data[key] = @@defaults[key] }
  end

  # Returns the value for the given configuration entry
  #
  # You can pass strings or symbols to this method.
  # Returns the standard value if the configuration entry is not set.
  def [](key) : YAML::Type
    query = @@data[key.to_s]?
    if query
      query
    else
      @@defaults[key.to_s]?
    end
  end

  # Sets a given configuration entry to a new value
  def []=(key, value)
    @@data[key.to_s] = convert(value)
  end

  # Converts incompatible primitive types to YAML::Type
  private def convert(v) : YAML::Any
    (if v.is_a?(YAML::Any)
      v
    elsif v.is_a?(Int8 | Int16 | Int32 | Int64 | UInt8 | UInt16 | UInt32 | UInt64)
      YAML::Any.new v.to_i64
    elsif v.is_a?(Float32 | Float64)
      YAML::Any.new v.to_f64
    elsif v.is_a?(String)
      YAML::Any.new v
    elsif v.is_a?(Array)
      YAML::Any.new v.map { |item| convert(item).as(YAML::Any) }
    elsif v.is_a?(Hash)
      YAML::Any.new Hash(YAML::Any, YAML::Any).zip(v.keys.map { |key| convert(key).as(YAML::Any) }, v.values.map { |value| convert(value).as(YAML::Any) })
    else
      raise "Cant convert #{v.class} to YAML::Any"
    end).as(YAML::Any)
  end

  # Saves the configuration to a file with given file name (using `Util#write_file`)
  def save(fname : String = "config.yml")
    Util.write_file(fname, YAML.dump(@@data))
  end

  # Returns the yaml dump of the configuration data
  def dump
    YAML.dump(@@data)
  end

  # Loads configuration values from the given file (using `Util#read_file`)
  def load(fname : String = "config.yml")
    data = YAML.parse(Util.read_file(fname)).as_h
    keys = data.keys.map(&.to_s)
    @@data = Hash.zip(keys, data.values)
  rescue ex
    Logger.error "Error loading config file! Loading defaults. Exception: #{ex}"
    load_defaults()
  end
end
