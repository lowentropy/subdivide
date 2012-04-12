class ObjFile
  attr_reader :vertices, :faces
  def initialize
    clear
  end
  def self.read filename
    new.parse(filename)
  end
  def parse filename
    File.open filename do |f|
      f.each_line &method(:parse_line)
    end
    self
  end
  def clear
    @vertices = []
    @faces = []
  end
  def add_vertex coords
    vertices << coords.map(&:to_f)
  end
  def add_face indices
    faces << indices.map(&:to_i)
  end
  def to_obj
    v = vertices.map {|v| "v #{v.join ' '}"}
    f = faces.map {|f| "f #{f.join ' '}"}
    (v + f).join "\n"
  end
private
  def parse_line line
    cmd, *args = line.split(/\s+/)
    case cmd
      when 'v' then add_vertex args
      when 'f' then add_face args
    end
  end
end
