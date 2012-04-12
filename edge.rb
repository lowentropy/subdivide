require 'ext'
require 'face'

class Edge
  attr_accessor :head, :tail, :left, :right, :twin, :_next, :next_position, :part1, :part2, :desc
  def initialize head, tail, left, desc="normal"
    @head, @tail, @left = head, tail, left
    head.edges << self
    tail.edges << self
    @desc = desc
  end
  def boundary?
    !twin
  end
  def find_next_position
    @next_position = if twin.try(:next_position)
      twin.next_position
    elsif boundary?
      (head + tail) / 2
    else
      ((head + tail) * 3 + face_vertices.sum) / 8
    end
  end
  def face_vertices
    [_next.tail, twin._next.tail]
  end
  def other_vertex v
    (v == head) ? tail : head
  end
  def opposite face
    edge = Edge.new tail, head, face, "inner"
    edge.right = left
    edge.twin = self
    self.twin = edge
    self.right = face
    edge
  end
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
  def relink
    if twin
      part1.twin = twin.part2
      part2.twin = twin.part1
      part1.right = part1.twin.left
      part2.right = part2.twin.left
    end
  end
  def cleanup
    self.part1 = (self.part2 = nil)
    head.remove_edge self
    tail.remove_edge self
  end
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
  def assert_count_self source, dir
    arr = send(source).edges_with(dir, send(dir))
    num = arr.select { |edge| edge == self }.size
    assert num == 1, "#{source}'s #{dir}"
  end
  def to_s
    "<Edge #{desc} id:#{id} head:#{head.id} tail:#{tail.id} left:#{left.id} right:#{right.id} twin:#{twin.id} part1:#{part1.id} part2:#{part2.id}>"
  end
end