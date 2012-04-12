require 'ext'

class Face
  attr_accessor :vertices, :edges, :odd_edge
  def boundary?
    edges.any? &:boundary?
  end
  def subdivide
    faces = edges.map &:subdivide
    face = Face.new
    face.edges = faces.map(&:odd_edge).map { |edge| edge.opposite face }
    face.circle!
    face.vertices = face.edges.map &:head
    faces.unshift face
  end
  def circle!
    0.upto(2) { |i| edges[i]._next = edges[(i+1)%3] }
  end
  def assert_sanity
    0.upto(2) do |i|
      j = (i + 1) % 3
      assert edges[i]._next == edges[j], "edge next: #{i} -> #{j}"
      assert edges[i].head == vertices[i], "edge head #{i}"
      assert edges[i].tail == vertices[j], "edge tail #{i}"
      assert edges[i].left == self, "left is face"
    end
  end
  def to_obj
    a, b, c = vertices
    indices = vertices.map {|v| v.index + 1}
    "f #{indices.join ' '}"
  end
end
