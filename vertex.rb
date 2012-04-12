require 'ext'

include Math

# Calculate β for interior, even vertices in Loop subdivision.
# `n` is the total number of vertices in the mask (including the
# center vertex (TODO: find out if that's really correct))
BETA = {}
def loop_beta n
  BETA[n] ||= begin
    if n == 3
      3.0 / 16
    else
      #3.0 / (8 * n)
      (1.0 / n) * (0.625 - (0.375 + 0.25 * cos(2 * PI / n)) ** 2)
    end
  end
end

# Vertices are shared among edges and faces. A vertex can be connected
# to any number of faces, but adjoining faces will always have two
# vertices in common. In this case, there will be two edges sharing
# the same two vertices, but their head/tail orientation will be
# switched to keep the edges in counter-clockwise order around their
# respective faces.
class Vertex
  attr_accessor :x, :y, :z, :edges, :index
  
  # Make a new, unconnected vertex with the given 3d coordinates
  def initialize coords
    @x, @y, @z = coords
    @edges = []
  end
  
  # Remove the given edge from our spoke edges
  def remove_edge edge
    @edges.delete edge
  end
  
  # A vertex is on the boundary of a surface if at lease
  # one of the edges connected to it is a boundary edge.
  def boundary?
    edges.any? &:boundary?
  end
  
  # Find all the edges connected to this vertex where the given
  # end (either head or tail) of the edge is equal to the given
  # vertex.
  def edges_with(dir, vertex)
    edges.select { |edge| edge.send(dir) == vertex }
  end
  
  # Find the edge connected to this vertex which has the given
  # head and tail.
  def edge_with(head, tail)
    edges.find { |edge| edge.head == head && edge.tail == tail }
  end
  
  # Move the vertex to the subdivision-adjusted position chosen
  # for it by `next_position`.
  def move
    self.x = @next_position.x
    self.y = @next_position.y
    self.z = @next_position.z
  end
  
  # Find the position to which we should move this vertex to
  # maintain a smooth surface.
  def find_next_position
    @next_position = if boundary?
      (boundary_vertices.sum + self * 6) / 8
    else
      others = edges.map { |edge| edge.other_vertex self }.uniq
      k = others.size
      n = k + 1
      b = loop_beta n
      others.sum * b + self * (1 - k * b)
    end
  end
  
  # This should only be called on a boundary vertex. Find the other
  # two vertices which share a boundary edge with this vertex.
  def boundary_vertices
    edges.select(&:boundary?).map { |edge| edge.other_vertex self }
  end
  
  # Multiply the vertex coordinates by a scalar, creating a new unconnected
  # vertex.
  def * s
    Vertex.new [x*s, y*s, z*s]
  end
  
  # Divide the vertex coordinates by a scalar, creating a new unconnected
  # vertex.
  def / s
    self * (1.0 / s)
  end
  
  # Add the coordinates of two vertices, creating a new unconnected
  # vertex.
  def + v
    Vertex.new [x+v.x, y+v.y, z+v.z]
  end
  
  # Subtract the coordinates of two vertices, creating a new unconnected
  # vertex.
  def - v
    self + (v * -1.0)
  end
  
  # Return the (x, y, z) string representation of this vertex.
  def to_s
    "(#{x}, #{y}, #{z})"
  end
  
  # Generate a line of a Wavefront .obj file for this vertex.
  def to_obj
    "v #{x} #{y} #{z}"
  end
  
  # Ensure the data integrity of this vertex.
  def assert_sanity
    assert @edges.size == @edges.uniq.size, "unique edges on vertex"
    assert boundary_vertices.size == 2, "2 boundary vertices" if boundary?
  end
end
