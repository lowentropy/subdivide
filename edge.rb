require 'ext'
require 'face'

# An edge links two vertices of a face. The head and tail are chosen
# so that the tail of one edge is the head of the next one, in counter-
# clockwise order. For adjoining faces, the shared edge is actually
# two edges who are each others' `twin`. The `left` face of the edge
# is the one to which it belongs; the `right` face is the `twin`'s
# face, if any. Edges use `_next` to form a circularly linked list
# around the boundary of the face. `part1` and `part2` represent the
# sub-edges after subdivision occurs. The edge will calculate its own
# `part2` from the edge midpoint, and the `part1` of its `_next` edge.
class Edge
  attr_accessor :head, :tail, :left, :right, :twin, :_next, :next_position, :part1, :part2, :desc
  
  # Create an edge between the given vertices and belonging to the
  # given face.
  def initialize head, tail, left, desc="normal"
    @head, @tail, @left = head, tail, left
    head.edges << self
    tail.edges << self
    @desc = desc
  end
  
  # An edge is on the boundary of the surface if it does NOT have
  # a twin edge, i.e. if its face does not adjoin another face on
  # this edge.
  def boundary?
    !twin
  end
  
  # Find a point on this edge (or even slightly off it) where a
  # new vertex should be inserted for subdivision. Since the calculation
  # is symmetric with the twin (if any), don't repeat the calculation
  # if the twin already has a `next_position`. Boundary edges and 
  # interior edges are treated differently (in Loop subdivision).
  def find_next_position
    @next_position = if twin.try(:next_position)
      twin.next_position
    elsif boundary?
      (head + tail) / 2
    else
      ((head + tail) * 3 + face_vertices.sum) / 8
    end
  end
  
  # The 'face vertices' (only defined on interior edges) are the
  # two vertices of the faces on either side of this edge that are
  # not themselves the head or tail of this edge:
  # 
  #    X
  #   / \
  #  /___\ E
  #  \  /
  #   \/
  #    X
  def face_vertices
    [_next.tail, twin._next.tail]
  end
  
  # Find the vertex connected to this edge which is NOT
  # the given vertex, i.e. find the vertex connected to the
  # given one by this edge.
  def other_vertex v
    (v == head) ? tail : head
  end
  
  # Create a new edge, twinned to this one, which belongs to
  # the given face.
  def opposite face
    edge = Edge.new tail, head, face, "inner"
    edge.right = left
    edge.twin = self
    self.twin = edge
    self.right = face
    edge
  end
  
  # Subdivide the edge. For two connected edges on the boundary of
  # a face (this edge and its `_next` edge), the new face is defined
  # by the new midpoints of the edges and their shared vertex.
  def subdivide
    face = Face.new
    face.vertices = [next_position, tail, _next.next_position]
    
    self.part2 = Edge.new next_position, tail, face, "part2"
    _next.part1 = Edge.new tail, _next.next_position, face, "part1"
    face.odd_edge = Edge.new _next.next_position, next_position, face, "odd_edge"
    
    face.edges = [self.part2, _next.part1, face.odd_edge]
    
    self.part2._next = _next.part1
    _next.part1._next = face.odd_edge
    face.odd_edge._next = self.part2
    
    face
  end
  
  # This edge and its twin (if any) have been subdivided into two
  # parts apiece. Link the corresponding sub-edges together as
  # twins.
  def relink
    if twin
      part1.twin = twin.part2
      part2.twin = twin.part1
      part1.right = part1.twin.left
      part2.right = part2.twin.left
    end
  end
  
  # Remove the sub-edges since we don't need them any more, and
  # remove our edge from the vertices it used to connect, since
  # those vertices are now only connected by our subdivided edges.
  def cleanup
    self.part1 = (self.part2 = nil)
    head.remove_edge self
    tail.remove_edge self
  end
  
  # Ensure the data integrity of this edge.
  def assert_sanity
    assert _next._next._next == self, "circular"
    assert twin.twin == self, "twin" if twin
    assert left, "left"
    assert right, "right" if twin
    assert twin, "inner" if desc == 'inner'
    assert_count_self(:head, :head)
    assert_count_self(:head, :tail)
    assert_count_self(:tail, :head)
    assert_count_self(:tail, :tail)
    assert head.edge_with(head, tail) == self, "head has head and tail"
    assert tail.edge_with(head, tail) == self, "tail has head and tail"
  end
  
  # Asser that the vertex in the given `source` direction lists
  # this edge exactly once in the given `dir` direction.
  def assert_count_self source, dir
    arr = send(source).edges_with(dir, send(dir))
    num = arr.select { |edge| edge == self }.size
    assert num == 1, "#{source}'s #{dir}"
  end
  
  # Return a handy debugging representation of this edge.
  def to_s
    "<Edge #{desc} id:#{id} head:#{head.id} tail:#{tail.id} left:#{left.id} right:#{right.id} twin:#{twin.id} part1:#{part1.id} part2:#{part2.id}>"
  end
end