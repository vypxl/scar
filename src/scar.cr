require "crsfml"
require "chipmunk"
require "msgpack"

module Scar
end

# Use this instead of initialize if you want a serializable type.
# It creates a initialize method and a MessagePack mapping to use it with
# `to_msgpack` and `from_msgpack` and getter/setter methods for all fields.
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
#   MessagePack.mapping({name: String, age: UInt32, friend_names: Array(String)})
# end
# ```
macro serializable(fields)
  def initialize({% for k, v, i in fields %}@{{k.id}} : {{v.id}}{% if i < fields.size - 1 %}, {% end %}{% end %}); end
  MessagePack.mapping({{fields}}, strict = true)
end

require "./scar/*"
