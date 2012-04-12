# This file can read and write Wavefront .obj files in a very
# limited way. It supports the 'v' and 'f' commands and ignores the
# rest.
class ObjFile
  attr_reader :vertices, :faces
  
  def initialize
    clear
  end
  
  # Create an `ObjFile` from the given filename.
  def self.read filename
    new.parse(filename)
  end
  
  # Parse the given file and set our contents to match.
  def parse filename
    clear
    File.open filename do |f|
      f.each_line &method(:parse_line)
    end
    self
  end
  
  # Empty the .obj
  def clear
    @vertices = []
    @faces = []
  end
  
  # Add a vertex triple
  def add_vertex coords
    vertices << coords.map(&:to_f)
  end
  
  # Add a face index triple
  def add_face indices
    faces << indices.map(&:to_i)
  end
  
  # Generate a new .obj file. This will only include 'v' and 'f'
  # commands.
  def to_obj
    v = vertices.map {|v| "v #{v.join ' '}"}
    f = faces.map {|f| "f #{f.join ' '}"}
    (v + f).join "\n"
  end
  
private

  # Parse a single line from the input file. All commands
  # besides 'v' and 'f' are ignored.
  def parse_line line
    cmd, *args = line.split(/\s+/)
    case cmd
      when 'v' then add_vertex args
      when 'f' then add_face args
    end
  end
end
