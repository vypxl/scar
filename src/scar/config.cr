module Scar
  # Use this to store basic configuration like Keybindings, resolutions..
  # Can store all types of the YAML::Type alias.
  module Config
    extend self

    @@data : Hash(String, YAML::Type) = Hash(String, YAML::Type).new
    @@standards : Hash(String, YAML::Type) = Hash(String, YAML::Type).new

    # Sets given key to it's standard. (`Config#define_standards`)
    def standardize(key)
      @@data[key.to_s] = @@standards[key.to_s]?
    end

    # Define standard values to keys. See details.
    # Specify the standards via a NamedTuple of format '<keyname>: <value>'.
    # Usage:
    # ```
    # Scar::Config.define_standards({
    #   str: "hello world",
    #   arr: [1, 3, 3, 7],
    # })
    # ```
    macro define_standards(standards)
      module Scar::Config
        @@standards = Hash(String, YAML::Type) {
          {% for k, v, i in standards %}"{{k.id}}" => convert({{v}}){% if i < standards.size - 1 %},{% end %}
          {% end %}
        }
        load_standards()
      end
    end

    # Resets all configuration to the standard values.
    def load_standards
      @@data = Hash(String, YAML::Type).new
      @@standards.each_key { |key| @@data[key] = @@standards[key] }
    end

    # Returns the value for the given key (String representation is used: 'Config[:test]' is possible) or if nil the standard value.
    def []?(key) : YAML::Type
      query = @@data[key.to_s]?
      if query
        query
      else
        @@standards[key.to_s]?
      end
    end

    # Sets a given key to a new value
    def []=(key, value)
      @@data[key.to_s] = convert(value)
    end

    # Converts incompatible primitive types to YAML::Type
    private def convert(v) : YAML::Type
      (if v.is_a?(YAML::Type)
        v
      elsif v.is_a?(Int8 | Int16 | Int32 | UInt8 | UInt16 | UInt32 | UInt64)
        v.to_i64
      elsif v.is_a?(Float32)
        v.to_f64
      elsif v.is_a?(Array)
        v.map { |item| convert(item).as(YAML::Type) }
      elsif v.is_a?(Hash)
        Hash(YAML::Type, YAML::Type).zip(v.keys.map { |key| convert(key).as(YAML::Type) }, v.values.map { |value| convert(value).as(YAML::Type) })
      else
        raise "Cant convert #{v.class} to YAML::Type"
      end).as(YAML::Type)
    end

    # Saves config to file with given file name (using `Util#write_file`)
    def save(fname : String)
      Util.write_file(fname, YAML.dump(@@data))
    end

    # Returns the yaml dump of the config data
    def dump
      YAML.dump(@@data)
    end

    # Loads in config values from given filename (using `Util#read_file`)
    def load(fname : String)
      data = YAML.parse(Util.read_file(fname)).as_h
      keys = data.keys.map(&.to_s)
      @@data = Hash.zip(keys, data.values)
    rescue ex
      Logger.error "Error loading config file! Loading standard. Exception: #{ex}"
      load_standards()
    end
  end # End module Config
end   # End module Scar
