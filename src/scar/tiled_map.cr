require "base64"
require "compress/zlib"
require "compress/gzip"
require "zstd"

# This module contains definitions for Tiled's JSON map format
# Refer to https://doc.mapeditor.org/en/stable/reference/json-map-format/ for more explaination
# Last updated for Tiled v1.7.2
module Scar::Tiled
  class Map
    include JSON::Serializable

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property backgroundcolor : SF::Color?

    property compressionlevel : Int32
    property height : Int32
    property hexsidelength : Int32 = 0
    property infinite : Bool
    property layers : Array(Layer)
    property nextlayerid : Int32
    property nextobjectid : Int32
    property orientation : Orientation
    property properties : Array(Property) = [] of Property
    property renderorder : RenderOrder = RenderOrder::RightDown
    property staggeraxis : StaggerAxis = StaggerAxis::X
    property staggerindex : StaggerIndex = StaggerIndex::Odd
    property tiledversion : String
    property tileheight : Int32
    property tilesets : Array(Tileset)
    property tilewidth : Int32
    property type : String
    property version : String
    property width : Int32
  end

  class Layer
    include JSON::Serializable
    include JSON::Serializable::Strict

    use_json_discriminator "type", {tilelayer: TileLayer, imagelayer: ImageLayer, objectgroup: ObjectGroup, group: Group}

    property type : String
  end

  class TileLayer < Layer
    property chunks : Array(Chunk) = [] of Chunk

    @[JSON::Field(converter: Scar::Tiled::CompressionConverter)]
    property compression : Compression = Compression::None

    @[JSON::Field(key: "data")]
    @_rawdata : Array(Int32) | String | Nil
    @[JSON::Field(ignore: true)]
    property data : Array(Int32) = [] of Int32

    property encoding : Encoding = Encoding::Csv
    property height : Int32
    property id : Int32
    property name : String
    property offsetx : Float64 = 0.0
    property offsety : Float64 = 0.0
    property opacity : Float64 = 1.0
    property parallaxx : Float64 = 1.0
    property parallaxy : Float64 = 1.0
    property properties : Array(Property) = [] of Property
    property startx : Int32 = 0
    property starty : Int32 = 0

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property tintcolor : SF::Color?

    property visible : Bool
    property width : Int32
    property x : Int32
    property y : Int32

    def after_initialize
      raw = @_rawdata
      @data = Scar::Tiled.parse_tiledata(raw, @width * @height, @compression) unless raw.nil?

      @chunks.each do |chunk|
        chunk.data = Scar::Tiled.parse_tiledata(chunk.@_rawdata, chunk.@width * chunk.@height, @compression)
      end
    end

    def [](x : Int32, y : Int32) : Int32
      raise NotImplementedError.new("[] for TileLayer")
    end
  end

  class ImageLayer < Layer
    property id : Int32
    property image : String?
    property name : String
    property offsetx : Float64 = 0.0
    property offsety : Float64 = 0.0
    property opacity : Float64 = 1.0
    property parallaxx : Float64 = 1.0
    property parallaxy : Float64 = 1.0
    property properties : Array(Property) = [] of Property

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property tintcolor : SF::Color?

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property transparentcolor : SF::Color?

    property visible : Bool
    property x : Int32
    property y : Int32
  end

  class ObjectGroup < Layer
    property draworder : DrawOrder = DrawOrder::Topdown
    property id : Int32
    property name : String
    property objects : Array(Object)
    property offsetx : Float64 = 0.0
    property offsety : Float64 = 0.0
    property opacity : Float64 = 1.0
    property parallaxx : Float64 = 1.0
    property parallaxy : Float64 = 1.0
    property properties : Array(Property) = [] of Property

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property tintcolor : SF::Color?

    property visible : Bool
    property x : Int32
    property y : Int32
  end

  class Group < Layer
    property id : Int32
    property layers : Array(Layer)
    property name : String
    property offsetx : Float64 = 0.0
    property offsety : Float64 = 0.0
    property opacity : Float64 = 1.0
    property parallaxx : Float64 = 1.0
    property parallaxy : Float64 = 1.0
    property properties : Array(Property) = [] of Property

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property tintcolor : SF::Color?

    property visible : Bool
    property x : Int32
    property y : Int32
  end

  class Chunk
    include JSON::Serializable
    include JSON::Serializable::Strict

    @[JSON::Field(key: "data")]
    @_rawdata : Array(Int32) | String
    @[JSON::Field(ignore: true)]
    property data : Array(Int32) = [] of Int32
    property height : Int32
    property width : Int32
    property x : Int32
    property y : Int32
  end

  class Object
    include JSON::Serializable
    include JSON::Serializable::Strict

    property id : Int32

    property height : Float64 = 0
    property name : String = ""
    property properties : Array(Property) = [] of Property
    property rotation : Float64 = 0
    property type : String = ""
    property visible : Bool = true
    property width : Float64 = 0

    property x : Float64
    property y : Float64

    def self.new(pull : JSON::PullParser)
      kind = Rectangle

      json = String.build do |io|
        JSON.build(io) do |builder|
          builder.start_object
          pull.read_object do |key|
            kind = case key
                   when "ellipse"
                     Ellipse
                   when "point"
                     PointObject
                   when "polygon"
                     Polygon
                   when "polyline"
                     Polyline
                   when "text"
                     TextObject
                   when "gid"
                     TileObject
                   when "template"
                     TemplateInstance
                   else
                     kind
                   end

            builder.field(key) { pull.read_raw(builder) }
          end
          builder.end_object
        end
      end

      kind.from_json(json)
    end
  end

  class Ellipse < Object
    property ellipse : Bool
  end

  class PointObject < Object
    property point : Bool
  end

  class Polygon < Object
    property polygon : Array(Point)
  end

  class Polyline < Object
    property polyline : Array(Point)
  end

  class TextObject < Object
    property text : Text
  end

  class Rectangle < Object
  end

  class TileObject < Object
    property gid : Int32
  end

  # TODO somehow load the templates
  class TemplateInstance < Object
    property template : String
  end

  class Text
    include JSON::Serializable
    include JSON::Serializable::Strict

    property bold : Bool = false

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property color : SF::Color = SF::Color::Black

    property fontfamily : String = "sans-serif"
    property halign : HAlign = HAlign::Left
    property italic : Bool = false
    property kerning : Bool = true
    property pixelsize : Int32 = 16
    property strikeout : Bool = false
    property text : String
    property underline : Bool = false
    property valign : VAlign = VAlign::Top
    property wrap : Bool = false
  end

  class Tileset
    include JSON::Serializable
    include JSON::Serializable::Strict

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property backgroundcolor : SF::Color?
    property columns : Int32 = 0
    property firstgid : Int32
    property grid : Grid?
    property image : String = ""
    property imageheight : Int32 = 0
    property imagewidth : Int32 = 0
    property margin : Int32 = 0
    property name : String = ""
    property objectalignment : ObjectAlignment = ObjectAlignment::Unspecified
    property properties : Array(Property) = [] of Property
    property source : String?
    property spacing : Int32 = 0
    property terrains : Array(Terrain)?
    property tilecount : Int32 = 0
    property tiledversion : String?
    property tileheight : Int32 = 0
    property tileoffset : TileOffset?
    property tiles : Array(Tile) = [] of Tile
    property tilewidth : Int32 = 0
    property transformations : Transformations?

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property transparentcolor : SF::Color?

    property type : String?
    property version : String?
    property wangsets : Array(WangSet) = [] of WangSet
  end

  class Grid
    include JSON::Serializable
    include JSON::Serializable::Strict

    property height : Int32
    property orientation : Orientation = Orientation::Orthogonal
    property width : Int32
  end

  class TileOffset
    include JSON::Serializable
    include JSON::Serializable::Strict

    property x : Int32
    property y : Int32
  end

  class Transformations
    include JSON::Serializable
    include JSON::Serializable::Strict

    property hflip : Bool
    property vflip : Bool
    property rotate : Bool
    property preferuntransformed : Bool
  end

  # TODO load image maybe?
  class Tile
    include JSON::Serializable
    include JSON::Serializable::Strict

    property animation : Array(Frame) = [] of Frame
    property id : Int32
    property image : String?
    property imageheight : Int32 = 0
    property imagewidth : Int32 = 0
    property objectgroup : Layer?
    property probability : Float64?
    property properties : Array(Property) = [] of Property
    property terrain : Array(Int32)?
    property type : String?
  end

  class Frame
    include JSON::Serializable
    include JSON::Serializable::Strict

    property duration : Int32
    property tileid : Int32
  end

  class Terrain
    include JSON::Serializable
    include JSON::Serializable::Strict

    property name : String = ""
    property properties : Array(Property) = [] of Property
    property tile : Int32
  end

  class WangSet
    include JSON::Serializable
    include JSON::Serializable::Strict

    property colors : Array(WangColor)
    property name : String = ""
    property properties : Array(Property) = [] of Property
    property tile : Int32
    property type : WangSetType
    property wangtiles : Array(WangTile)
  end

  class WangColor
    include JSON::Serializable
    include JSON::Serializable::Strict

    @[JSON::Field(converter: Scar::Tiled::ColorConverter)]
    property color : SF::Color

    property name : String = ""
    property probability : Float64
    property properties : Array(Property) = [] of Property
    property tile : Int32
  end

  class WangTile
    include JSON::Serializable
    include JSON::Serializable::Strict

    property tileid : Int32
    property wangid : Array(Int32)
  end

  class ObjectTemplate
    include JSON::Serializable
    include JSON::Serializable::Strict

    property type : String
    property tileset : Tileset?
    property object : Object
  end

  class Property
    include JSON::Serializable
    include JSON::Serializable::Strict

    property name : String
    property type : String
    # TODO: use type field as in https://crystal-lang.org/api/1.1.1/JSON/Serializable.html#use_json_discriminator(field,mapping)-macro
    property value : String | Int32 | Float32 | Bool
  end

  class Point
    include JSON::Serializable
    include JSON::Serializable::Strict

    property x : Float64
    property y : Float64
  end

  # Enums
  enum Orientation
    Orthogonal
    Isometric
    Staggered
    Hexagonal
  end

  enum RenderOrder
    RightDown
    RightUp
    LeftDown
    LeftUp

    def self.parse?(string : String) : self?
      case string
      when "right-down"
        RightDown
      when "right-up"
        RightUp
      when "left-down"
        LeftDown
      when "left-up"
        LeftUp
      else
        nil
      end
    end

    def to_json(json : JSON::Builder)
      json.string(case self
      when RightDown
        "right-down"
      when RightUp
        "right-up"
      when LeftDown
        "left-down"
      when LeftUp
        "left-up"
      end)
    end
  end

  enum StaggerAxis
    X
    Y
  end

  enum StaggerIndex
    Odd
    Even
  end

  enum Compression
    None
    Zlib
    Gzip
    Zstd
  end

  enum DrawOrder
    Topdown
    Index
  end

  enum Encoding
    Csv
    Base64
  end

  enum HAlign
    Center
    Right
    Justify
    Left
  end

  enum VAlign
    Center
    Top
    Bottom
  end

  enum ObjectAlignment
    Unspecified
    Topleft
    Top
    Topright
    Left
    Center
    Right
    Bottomleft
    Bottom
    Bottomright
  end

  enum WangSetType
    Corner
    Edge
    Mixed
  end

  # Converters
  module ColorConverter
    def self.from_json(pull : JSON::PullParser) : SF::Color
      raw : UInt32 = pull.read_string[1..].to_u32(16)
      SF::Color.new(((raw & 0xffffff) << 8) | (raw >> 24))
    end

    def self.to_json(value : SF::Color, json : JSON::Builder)
      raw = value.to_integer
      conv = ((raw & 0xff) << 24) | (raw >> 8)
      json.string('#' + conv.to_s(16).rjust(6, '0'))
    end
  end

  module CompressionConverter
    def self.from_json(pull : JSON::PullParser) : Compression
      loc = pull.location
      raw : String = pull.read_string
      case raw
      when ""
        Compression::None
      when "zlib"
        Compression::Zlib
      when "gzip"
        Compression::Gzip
      when "zstd"
        Compression::Zstd
      else
        msg = "Unknown enum Scar::Tiled::Compression value: \"#{raw}\""
        raise JSON::ParseException.new(msg, loc[0], loc[1])
      end
    end

    def self.to_json(value : Compression, json : JSON::Builder)
      json.string(case value
      when Compression::None
        ""
      when Compression::Zlib
        "zlib"
      when Compression::Gzip
        "gzip"
      when Compression::Zstd
        "zstd"
      end)
    end
  end

  # Parse the `data` field of TileLayers or Chunks to an Array of tile ids
  def self.parse_tiledata(raw : Array(Int32) | String, tile_count : Int32, compression : Compression = Compression::None) : Array(Int32)
    if raw.is_a? Array(Int32)
      # Do not decompress if it is not compressed (duh)
      raw
    else
      decoded = Base64.decode raw
      raw_io = IO::Memory.new decoded, false

      # Determine compression type and load the correct decompressor
      io = (case compression
      when Compression::None
        raw_io
      when Compression::Zlib
        Compress::Zlib::Reader.new(raw_io)
      when Compression::Gzip
        Compress::Gzip::Reader.new(raw_io)
      when Compression::Zstd
        Zstd::Decompress::IO.new(raw_io)
      else
        raw_io
      end)

      # Read the tile ids into an Array
      src = Bytes.new(tile_count * sizeof(Int32))
      io.read_fully(src)
      io.close
      src.unsafe_as(Slice(Int32)).to_a
    end

    # TODO: make data writeable (encode and compress data upon serialization) (tilelayer & chunk)
  end
end
