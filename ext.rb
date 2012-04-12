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
  def id
    'nil'
  end
end

class Array
  def sum
    return nil if empty?
    sum = self[0]
    1.upto(size - 1) do |index|
      sum += self[index]
    end
    sum
  end
end
