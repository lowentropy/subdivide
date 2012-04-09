def assert condition, message="FAIL"
  throw message unless condition
end

class Object
  def try *args, &block
    send *args, &block
  end
end

class NilClass
  def try *args
    nil
  end
end

class Surface
  attr_reader :vertex_list, :face_list
  def initialize vertex_list, face_list
    @vertex_list, @face_list = vertex_list, face_list
  end
  def link
    @vertices = vertex_list.map { |coords| Vertex.new coords }
    @faces = face_list.map do |indices|
      vertices = indices.map { |i| @vertices[i] }
      face = Face.new
      face.vertices = vertices
      vertices.each { |vertex| vertex.faces << face }
      prev = nil
      face.edges = [[0,1], [1,2], [2,0]].map do |(i,j)|
        head, tail = vertices[i], vertices[j]
        twin = head.edge_with(:tail, tail) ||
               tail.edge_with(:head, head)
        right = twin.try :left
        edge = Edge.new head, tail, face
        edge.right = right
        edge.twin = twin
        head.edges << edge
        tail.edges << edge
        puts twin # XXX
        if twin
          twin.twin = edge
          twin.right = face
        end
        prev._next = edge if prev
        prev = edge
      end
      prev._next = face.edges[0]
      face
    end
    @edges = @faces.map(&:edges).flatten
  end
  def subdivide
    @edges.each &:find_next_position
    @vertices.each &:find_next_position
    @faces = @faces.map(&:subdivide).flatten
    @edges.each &:relink
    @edges = @faces.map(&:edges).flatten
    @vertices = @faces.map(&:vertices).flatten.uniq
  end
  def to_s
    @faces.map do |face|
      face.vertices.join(' - ')
    end.join("\n")
  end
  def assert_sanity
    @faces.each &:assert_sanity
  end
end

class Edge
  attr_accessor :head, :tail, :left, :right, :twin, :_next, :next_position, :part1, :part2
  def initialize head, tail, left
    @head, @tail, @left = head, tail, left
  end
  def boundary?
    !!twin
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
    [_next.tail, twin.next.tail]
  end
  def other_vertex v
    (v == head) ? tail : head
  end
  def opposite face
    edge = Edge.new tail, head, face
    edge.right = left
    edge.twin = self
    self.twin = edge
    self.right = face
    edge
  end
  def subdivide
    face = Face.new
    face.vertices = [next_position, tail, _next.next_position]
    self.part2 = Edge.new next_position, tail, face
    _next.part1 = Edge.new tail, _next.next_position, face
    face.odd_edge = Edge.new _next.next_position, next_position, face
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
    self.part1 = (self.part2 = nil)
  end
  def assert_sanity
    assert _next._next._next == self, "circular"
    assert twin.twin == self, "twin" if twin
    assert left, "left"
    assert right, "right" if twin
    assert head.edge_with(:head, head) == self, "head's head"
    assert tail.edge_with(:tail, tail) == self, "tail's tail"
    assert head.edge_with(:tail, tail) == self, "heads' tail"
    assert tail.edge_with(:head, head) == self, "tails' head"
  end
end

class Face
  attr_accessor :vertices, :edges, :odd_edge
  def boundary?
    edges.any? &:boundary?
  end
  def subdivide
    faces = edges.map &:subdivide
    face = Face.new
    face.edges = faces.map(&:odd_edge).map { |edge| edge.opposite face }
    face.vertices = face.edges.map &:head
    faces.unshift face
  end
  def assert_sanity
    0.upto(2) do |i|
      j = (i + 1) % 3
      assert edges[i]._next == edges[j], "edge next: #{i} -> #{j}"
      assert edges[i].head == vertices[i], "edge head #{i}"
      assert edges[i].tail == vertices[j], "edge tail #{i}"
      assert edges[i].left == self, "left is face"
      edges[i].assert_sanity
    end
  end
end

class Vertex
  attr_accessor :x, :y, :z, :edges, :faces
  def initialize coords
    @x, @y, @z = coords
    @edges, @faces = [], []
  end
  def boundary?
    edges.any? &:boundary?
  end
  def edge_with(dir, vertex)
    edges.find { |edge| edge.send(dir) == vertex }
  end
  def find_next_position
    @next_position = if boundary?
      (boundary_vertices.sum + self * 3) / 8
    else
      others = edges.map { |edge| edge.other_vertex self }
      n = others.size
      b = beta n
      others.sum * b + self * (1 - n * b)
    end
  end
  def beta n
    (@beta ||= {})[n] ||= begin
      if n == 3
        0.1875
      else
        (1.0 / n) * (0.625 - (0.375 + 0.25 * Math.cos(2 * Math.PI / n)) ** 2)
      end
    end
  end
  def boundary_vertices
    edges.select(&:boundary?).map { |edge| edge.other_vertex self }
  end
  def * s
    Vertex.new [x*s, y*s, z*s]
  end
  def / s
    self * (1.0 / s)
  end
  def + v
    Vertex.new [x+v.x, y+v.y, z+v.z]
  end
  def - v
    self + (v * -1)
  end
  def to_s
    "(#{x}, #{y}, #{z})"
  end
end

if __FILE__ == $0
  p0 = [0,0,0]
  p1 = [1,0,0]
  p2 = [0,1,0]
  p3 = [1,1,0]
  f0 = [0,1,2]
  f1 = [1,3,2]
  surface = Surface.new [p0,p1,p2,p3], [f0,f1]
  surface.link
  puts surface
  surface.assert_sanity
end
