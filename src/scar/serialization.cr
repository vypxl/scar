# Use this instead of initialize if you want a serializable type.
# It creates a initialize method and a MessagePack, Yaml and Json mapping to use it with
# `to_msgpack` and `from_msgpack` or the yaml/json methods and getter/setter methods for all fields.
# Usage: instead of traditional initialize(),
# you specify a NamedTuple with format { <field_name>: <Type>, .. }.
# Example:
# ```
# include Scar
# class Person
#   serializable({name: String, age: UInt32, friend_names: Array(String)})
# end
#
# # generates
#
# class Person
#   property :name, :age, :friend_names # This already happens when doing the MessagePack.mapping but for completeness sake..
#   def initialize(@name : String, @age : UInt32, @friend_names : Array(String))
#   MessagePack.mapping({name: String, age: UInt32, friend_names: Array(String)}, strict = true)
#   YAML.mapping({name: String, age: UInt32, friend_names: Array(String)}, strict = true)
#   JSON.mapping({name: String, age: UInt32, friend_names: Array(String)}, strict = true)
# end
# Also generates simple to_s
# ```
macro serializable(fields = nil)
  {% if @type.abstract? %} HEY! Look Here: ->Use abstract_serializable in abstract classes!<- (makes sense, right?){% end %}
    # Dummy property for separating subclasses with same fields for serialization.
  {% name = ("__" + @type.name.gsub(/::/, "__").downcase.stringify).id %}
  @{{name}} = 1
  {% for key, value in fields %}
    {% fields[key] = {type: value} unless value.is_a?(HashLiteral) || value.is_a?(NamedTupleLiteral) %}
  {% end %}
  def initialize({% for k, v, i in fields %}@{{k.id}} : {{v[:type].id}}{% if i < fields.size - 1 %}, {% end %}{% end %}); end

  {% fields[name.stringify] = {type: Int32, default: 0, setter: false, getter: false} %}

  MessagePack.mapping({{fields}}, strict = true)
  YAML.mapping({{fields}}, strict = true)
  JSON.mapping({{fields}}, strict = true)

  def to_s
    String.new to_s(IO::Memory.new).bytes
  end

  def to_s(io : IO)
    io << {{ @type.id }}
    io << '('
    \{% for iv, i in (@type.instance_vars.select { |iv| iv.id != ("__" + @type.name.gsub(/::/, "__").downcase.stringify).id }) %}
      io << "@\{{iv.id}}="
      @\{{iv}}.to_s(io)
      \{% if i < (@type.instance_vars.select { |iv| iv.id != ("__" + @type.name.gsub(/::/, "__").downcase.stringify).id }).size - 1 %}io << ", "\{% end %}
    \{% end %}
    io << ')'
  end
end

# For empty classes (e. g. tag components)
# Same functionality as serializable
macro empty_serializable
  {% if @type.abstract? %} HEY! Look Here: ->Use abstract_serializable in abstract classes!<- (makes sense, right?){% end %}
  {% name = ("__" + @type.name.gsub(/::/, "__").downcase.stringify).id %}
  @{{name}} = 1
  def initialize(); end
  MessagePack.mapping({ {{name}}: {type: Int32, default: 0, setter: false, getter: false } })
  YAML.mapping(       { {{name}}: {type: Int32, default: 0, setter: false, getter: false } })
  JSON.mapping(       { {{name}}: {type: Int32, default: 0, setter: false, getter: false } })

  def to_s
    String.new to_s(IO::Memory.new).bytes
  end

  def to_s(io : IO)
    io << {{ @type.id }}
    io << '('
    \{% for iv, i in (@type.instance_vars.select { |iv| iv.id != ("__" + @type.name.gsub(/::/, "__").downcase.stringify).id }) %}
      io << "@\{{iv.id}}="
      @\{{iv}}.to_s(io)
      \{% if i < (@type.instance_vars.select { |iv| iv.id != ("__" + @type.name.gsub(/::/, "__").downcase.stringify).id }).size - 1 %}io << ", "\{% end %}
    \{% end %}
    io << ')'
  end
end

# For abstract classes
macro abstract_serializable
  # Necessary for msgpack serializing to work.
  def to_msgpack(%packer : MessagePack::Packer)
    to_msgpack(%packer)
  end

  def self.new(%pull : JSON::PullParser)
    location = %pull.location
    string = %pull.read_raw

    \{% for klass in @type.all_subclasses %}
    begin
      return \{{ klass }}.from_json(string)
    rescue JSON::ParseException
    end
    \{% end %}

    raise JSON::ParseException.new("Couldn't parse #{self} from #{string}", *location)
  end

  def self.new(%ctx : YAML::ParseContext, %node : YAML::Nodes::Node)
    \{% for klass in @type.all_subclasses %}
    begin
      return \{{ klass }}.new(%ctx, %node)
    rescue YAML::ParseException
    end
    \{% end %}

    raise YAML::ParseException.new("Couldn't parse #{self}", %node.location[0], %node.location[1])
  end

  def self.new(%pull : MessagePack::Unpacker)
    %hash = %pull.read_hash
    \{% for klass in @type.all_subclasses %}
    begin
      return \{{ klass }}.from_msgpack(%hash.to_msgpack)
    rescue MessagePack::UnpackException
    end
    \{% end %}

    raise MessagePack::UnpackException.new("Couldn't parse #{self}")
  end
end # End macro abstract_serializable

# Thoughts:
# Now, you have to include all abstract class properties within the mappings of the subclasses.
# Maybe someday TODO: automate this as well. But only when I have time for that
