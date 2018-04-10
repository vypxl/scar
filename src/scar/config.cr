require "msgpack"

module Scar
  # Use this to store basic configuration like Keybindings, resolutions..
  # Can store all types of the Value alias.
  module Config
    extend self

    # The types that can be stored via this module.
    alias Value = Nil | Bool | Int32 | Float32 | String | Bytes | Array(Value) | Hash(Value, Value)

    @@data : Hash(String, Value) = Hash(String, Value).new
    @@standards : Hash(String, Value) = Hash(String, Value).new

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
        @@standards = Hash(String, Value) {
          {% for k, v, i in standards %}"{{k.id}}" => convert({{v}}){% if i < standards.size - 1 %},{% end %}
          {% end %}
        }
        load_standards()
      end
    end

    # Resets all configuration to the standard values.
    def load_standards
      @@data = Hash(String, Value).new
      @@standards.each_key { |key| @@data[key] = @@standards[key] }
    end

    # Returns the value for the given key (String representation is used: 'Config[:test]' is possible) or if nil the standard value.
    def []?(key) : Value
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

    # Converts incompatible primitive types to Value
    private def convert(v) : Value
      (if v.is_a?(Value)
        v
      elsif v.is_a?(Int8 | Int16 | Int64 | UInt8 | UInt16 | UInt32 | UInt64)
        v.to_i32
      elsif v.is_a?(Float64)
        v.to_f32
      elsif v.is_a?(Array)
        v.map { |item| convert(item).as(Value) }
      elsif v.is_a?(Hash)
        Hash(Value, Value).zip(v.keys.map { |key| convert(key).as(Value) }, v.values.map { |value| convert(value).as(Value) })
      else
        raise "Cant convert #{v.class} to Scar::Config::Value"
      end).as(Value)
    end

    # Converts Value to MessagePack::Type
    private def to_msgp_type(v : Value) : MessagePack::Type
      (if v.is_a?(Array)
        v.map { |item| to_msgp_type(item).as(MessagePack::Type) }
      elsif v.is_a?(Hash)
        Hash.zip(v.keys.map { |key| to_msgp_type(key).as(MessagePack::Type) }, v.values.map { |value| to_msgp_type(value).as(MessagePack::Type) })
      else
        v
      end).as(MessagePack::Type)
    end

    # Saves config to file with given file name (using `Util#write_file`)
    def save(fname : String)
      Util.write_file_bytes(fname, MessagePack.pack(Hash.zip(@@data.keys, @@data.values.map { |item| to_msgp_type(item) })))
    end

    # Loads in config values from given filename (using `Util#read_file`)
    def load(fname : String)
      data = MessagePack::Unpacker.new(Util.read_file(fname)).read_hash
      mapped = data.select { |k, v| k.is_a?(String) }
      keys = mapped.keys.map(&.to_s)
      vals = mapped.values.map { |v| convert(v) }
      @@data = Hash.zip(keys, vals)
    rescue ex
      Logger.error "Error loading config file! Loading standard. Exception: #{ex}"
      load_standards()
    end
  end # End module Config
end   # End module Scar
