require 'vertex'

# A surface consists of a list of interconnected vertices, faces,
# and edges. It can incrementally subdivide its faces to generate
# a smoother mesh. The surface can either be closed or open.
class Surface
  attr_reader :vertex_list, :face_list
  
  # Initialize with vertices (represented by a list of triples of
  # x, y, and z), and faces (represented by triples of 
  # 1-based indices into the vertices, as in a .obj file)
  def initialize vertex_list, face_list
    @vertex_list, @face_list = vertex_list, face_list
  end
  
  # Use the linear vertex and face lists to generate vertices,
  # edges, and faces which are correctly interconnected and ready
  # to be subdivided.
  def link
    @vertices = vertex_list.map { |coords| Vertex.new coords }
    @faces = face_list.map do |indices|
      vertices = indices.map { |i| @vertices[i-1] }
      face = Face.new
      face.vertices = vertices
      prev = nil
      face.edges = (0..2).map do |i|
        head, tail = vertices[i], vertices[(i+1)%3]
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
    @initial = get_sizes
  end
  
  # Assign the `index` of each vertex to be in an arbitrary order.
  def assign_indices!
    @vertices.each_with_index do |vertex, index|
      vertex.index = index
    end
  end
  
  # Interpolate the faces and edges to generate a finer mesh. The new
  # mesh will have four times as many faces and edges, and twice as
  # many vertices (keeping in mind edges are doubled for internal
  # parts of the surface).
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
    @final = get_sizes
  end
  
  # Generate a handy debugging representation of the vertices of
  # the surface.
  def to_s
    @faces.map do |face|
      face.vertices.join(' - ')
    end.join("\n")
  end
  
  # Ensure the data integrity of the whole surface.
  def assert_sanity
    @faces.each &:assert_sanity
    @edges.each &:assert_sanity
    @vertices.each &:assert_sanity
  end
  
  # Create a valid Wavefront .obj file contents for the surface
  def to_obj
    lines = @vertices.map(&:to_obj) + @faces.map(&:to_obj)
    lines.join "\n"
  end
  
  # Generate a string suitable for printing that describes some
  # statistics about the surface and its subdivision properties.
  def stats
    "Started with #{stats_of(@initial)}\n" +
    "Ended with #{stats_of(@final)}"
  end
  
  # Return a hash consisting of the number of faces, vertices, and
  # edges in the surface. Keep in mind edges are doubled for interior
  # parts of the surface.
  def get_sizes
    {}.tap do |sizes|
      [:faces, :vertices, :edges].each do |kind|
        sizes[kind] = instance_variable_get("@#{kind}").size
      end
    end
  end
  
  # Return a stats-representation string of the given size hash.
  def stats_of sizes
    [:faces, :vertices, :edges].map do |kind|
      "#{sizes[kind]} #{kind}"
    end.join ', '
  end
end
