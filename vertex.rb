require 'ext'

include Math

class Vertex
  attr_accessor :x, :y, :z, :edges, :index
  def initialize coords
    @x, @y, @z = coords
    @edges = []
  end
  def remove_edge edge
    @edges.delete edge
  end
  def boundary?
    edges.any? &:boundary?
  end
  def edges_with(dir, vertex)
    edges.select { |edge| edge.send(dir) == vertex }
  end
  def edge_with(head, tail)
    edges.find { |edge| edge.head == head && edge.tail == tail }
  end
  def move
    self.x = @next_position.x
    self.y = @next_position.y
    self.z = @next_position.z
  end
  def find_next_position
    @next_position = if boundary?
      (boundary_vertices.sum + self * 6) / 8
    else
      others = edges.map { |edge| edge.other_vertex self }.uniq
      k = others.size
      n = k + 1
      b = beta n
      others.sum * b + self * (1 - k * b)
    end
  end
  def beta n
    (@beta ||= {})[n] ||= begin
      if n == 3
        3.0 / 16
      else
        #3.0 / (8 * n)
        (1.0 / n) * (0.625 - (0.375 + 0.25 * cos(2 * PI / n)) ** 2)
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
    self + (v * -1.0)
  end
  def to_s
    "(#{x}, #{y}, #{z})"
  end
  def to_obj
    "v #{x} #{y} #{z}"
  end
  def assert_sanity
    assert @edges.size == @edges.uniq.size, "unique edges on vertex"
    assert boundary_vertices.size == 2, "2 boundary vertices" if boundary?
  end
end