require 'ext'

# The face consists of three vertices and three edges. Even if the
# face adjoins another, it doesn't directly share an edge with it;
# instead, one edge of this face will be the 'twin' of an edge on
# the other faces. These twinned edges will have opposing `head`s and
# `tail`s. The vertices of the face are the `head`s of its edges, and
# both are maintained in counter-clockwise (right-handed) order.
class Face
  attr_accessor :vertices, :edges, :odd_edge
  
  # The face is a boundary of the surface if it contains at least one
  # edge on the boundary of the surface.
  def boundary?
    edges.any? &:boundary?
  end
  
  # Subdivide the face by subdividing each edge to get three faces, then
  # creating a face that sits in the middle of them. Like the triforce!
  #   
  #    /\
  #   /__\
  #  /\  /\
  # /__\/__\
  def subdivide
    faces = edges.map &:subdivide
    face = Face.new
    face.edges = faces.map(&:odd_edge).map { |edge| edge.opposite face }
    face.circle!
    face.vertices = face.edges.map &:head
    faces.unshift face
  end
  
  # Make each edge reference the `_next` one in counter-clockwise
  # order.
  def circle!
    0.upto(2) { |i| edges[i]._next = edges[(i+1)%3] }
  end
  
  # Ensure the data integrity of this face.
  def assert_sanity
    0.upto(2) do |i|
      j = (i + 1) % 3
      assert edges[i]._next == edges[j], "edge next: #{i} -> #{j}"
      assert edges[i].head == vertices[i], "edge head #{i}"
      assert edges[i].tail == vertices[j], "edge tail #{i}"
      assert edges[i].left == self, "left is face"
    end
  end
  
  # Return a Wavefront .obj line for this face. It uses 1-based
  # indices into the list of vertices.
  def to_obj
    a, b, c = vertices
    indices = vertices.map {|v| v.index + 1}
    "f #{indices.join ' '}"
  end
end
