require 'vertex'

class Surface
  attr_reader :vertex_list, :face_list
  def initialize vertex_list, face_list
    @vertex_list, @face_list = vertex_list, face_list
  end
  def link
    @vertices = vertex_list.map { |coords| Vertex.new coords }
    @faces = face_list.map do |indices|
      vertices = indices.map { |i| @vertices[i-1] }
      face = Face.new
      face.vertices = vertices
      prev = nil
      face.edges = [[0,1], [1,2], [2,0]].map do |(i,j)|
        head, tail = vertices[i], vertices[j]
        twin = head.edge_with(tail, head)
        right = twin.try :left
        edge = Edge.new head, tail, face
        edge.right = right
        edge.twin = twin
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
    assign_indices!
  end
  def assign_indices!
    @vertices.each_with_index do |vertex, index|
      vertex.index = index
    end
  end
  def subdivide
    @edges.each &:find_next_position
    @vertices.each &:find_next_position
    @faces = @faces.map(&:subdivide).flatten
    @edges.each &:relink
    @edges.each &:cleanup
    @vertices.each &:move
    @edges = @faces.map(&:edges).flatten
    @vertices = @faces.map(&:vertices).flatten.uniq
    assign_indices!
  end
  def to_s
    @faces.map do |face|
      face.vertices.join(' - ')
    end.join("\n")
  end
  def assert_sanity
    @faces.each &:assert_sanity
    @edges.each &:assert_sanity
    @vertices.each &:assert_sanity
  end
  def to_obj
    lines = @vertices.map(&:to_obj) + @faces.map(&:to_obj)
    lines.join "\n"
  end
end