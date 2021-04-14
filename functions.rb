#item[0]: item to print
def print(item = ["\n"])
  puts "#{item[0]}"
end

#arg_list[0]: list to remove from
#arg_list[1]: index to remove at
def remove_at(arg_list) 
  if arg_list.length != 2
    raise ArgumentError.new("Wrong amount of arguments. Got #{arg_list.length}, should be 2")
  elsif arg_list[0].class != Array
    raise TypeError.new("Argument 1 must be an Array! Was '#{arg_list[0].class}'")
  elsif arg_list[1].class != Integer
    raise TypeError.new("Argument 2 must be an integer! Was '#{arg_list[1].class}'")
  elsif arg_list[1] > arg_list[0].length - 1
    raise IndexError.new("Index out of bounds! Was '#{arg_list[1]}', Max is '#{arg_list[0].length - 1}'")
  elsif arg_list[1] < 0
    raise IndexError.new("Negative index. Was #{arg_list[1]}, '\
                         'must be zero or above")
  end
  arg_list[0].delete_at(arg_list[1])
  arg_list[0]
end

#list[0]: list to take length of
def len(list)
  list[0].length
end

#value[0]: value to try and convert to int
def int(value)
  puts value
  raise ArgumentError.new("Wrong amount of arguments. Got #{value.length}, '\
                          'should be 1") if value.length != 1
  begin
    Integer(value[0])
  rescue ArgumentError
    raise ArgumentError.new("Cannot convert value '#{value[0]}' to an integer!")
  end
end

#value[0]: value to convert to string
def string(value)
  raise ArgumentError.new("Wrong amount of arguments.'\ 
  ' Got #{value.length}, should be 1") if value.length != 1
  String(value[0])
end