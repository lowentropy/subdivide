require 'optparse'
require 'obj_file'
require 'ext'
require 'vertex'
require 'edge'
require 'face'
require 'surface'
require 'opts'

def main options
  
  # Read the input .obj file
  obj = ObjFile.read options[:file]  
  surface = Surface.new obj.vertices, obj.faces
  surface.link
  
  # Subdivide the surface and check its sanity
  options[:subdivisions].times { surface.subdivide }
  surface.assert_sanity if options[:check]
  
  # Output the subdivided file
  if options[:output] == '-'
    puts surface.to_obj
  else
    File.open options[:output], 'w' do |f|
      f.puts surface.to_obj
    end
  end
  
  # Print some statistics
  puts surface.stats if options[:verbose]
end

main get_options if __FILE__ == $0
