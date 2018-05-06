require "../spec_helper"

abstract struct Base
  abstract_serializable()
end

struct A
  serializable({arr: Array(Base)})
end

struct B < Base
  serializable({b: String})
end

struct C < Base
  empty_serializable()
end

example = A.new([B.new("hello world"), C.new])

describe "serialization macros" do
  it "can serialize and deserialize complex classes" do
    A.from_msgpack(example.to_msgpack).should eq example
    A.from_yaml(example.to_yaml).should eq example
    A.from_json(example.to_json).should eq example
  end
end
