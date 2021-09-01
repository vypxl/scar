# This Component is a simple way to draw a Tiled Tilemap.
# It only supports ungrouped TileLayers (finite or infinite)
# with an embedded Tileset referencing an Image whose path
# is recognized by `Scar::Assets`
#
# Does NOT support:
# - Layer Groups
# - External or multiple Tilesets
# - Renderorder other than right-down
# - Anything except orthogonal orientation
# - Tile transformations
# - Parallax effects
class Scar::Components::Tilemap < Scar::Component
  include Scar::Drawable

  getter map : Scar::Tiled::Map

  def map=(new_map : Scar::Tiled::Map)
    @map = new_map
    update_buffer
  end

  getter drawable : SF::VertexBuffer

  def initialize(@map)
    @texture = Assets.texture @map.tilesets[0].image
    @drawable = SF::VertexBuffer.new(SF::PrimitiveType::Triangles, SF::VertexBuffer::Usage::Static)

    update_buffer
  end

  # Rebuilds the VertexBuffer used to draw the Tilemap
  def update_buffer
    tw = @map.tilewidth
    th = @map.tileheight
    tex_row_width_in_tiles = @texture.size.x // tw

    verts = [] of SF::Vertex

    @map.layers.select(Scar::Tiled::TileLayer).each do |layer|
      [*layer.chunks, layer].each { |chunk|
        next if chunk.data.size == 0
        i = 0
        chunk.height.times { |_y|
          chunk.width.times { |_x|
            tile_id = chunk.data[i] & (0xffffffff >> 3) # mask out transformation bits
            x = _x + chunk.x
            y = _y + chunk.y

            unless tile_id == 0 # 0 == empty
              tile_id -= 1      # Substract one to get the actual tile index in the tileset
              tx = tw * (tile_id % tex_row_width_in_tiles)
              ty = th * (tile_id // tex_row_width_in_tiles)

              verts << SF::Vertex.new({x * tw, y * th}, {tx, ty})
              verts << SF::Vertex.new({x * tw, y * th + th}, {tx, ty + th})
              verts << SF::Vertex.new({x * tw + tw, y * th}, {tx + tw, ty})

              verts << SF::Vertex.new({x * tw + tw, y * th + th}, {tx + tw, ty + th})
              verts << SF::Vertex.new({x * tw, y * th + th}, {tx, ty + th})
              verts << SF::Vertex.new({x * tw + tw, y * th}, {tx + tw, ty})
            end

            i += 1
          }
        }
      }
    end

    @drawable.create(verts.size)
    @drawable.update(verts, 0)
  end
end
