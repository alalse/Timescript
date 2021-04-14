require 'time'
require_relative 'scope_handler.rb'

class Program_node
  def initialize(a)
    @program = a
  end

  def eval
    @program.eval
  end
end

class Statement_list_node
  def initialize(a, b = nil)
    #If 'b' is nil add statement 'a' to 'stmt_list'
    @stmt_list = []
    if b.nil?
      @stmt_list << a

    #Else add all statements from statement_list_node 'a' 
    #before adding 'b' to 'stmt_list'
    else
      a.get_statements.each do |elem|
        @stmt_list << elem
      end
      @stmt_list << b
    end
  end

  def get_statements
    @stmt_list
  end

  def eval
    last_stmt = nil
    @stmt_list.each do |stmt|
      break if Scope_handler.get_break_flag

      #Handles return
      if stmt.class == Return_node
        if Scope_handler.get_ongoing_function_calls == 0
          raise StandardError.new('Cannot return outside of a function!')
        end
        Scope_handler.set_return_flag(true)
        last_stmt = stmt.eval
        Scope_handler.set_return_value(last_stmt)
        break
      
      #Handles break
      elsif stmt.class == Break_node
        if Scope_handler.get_ongoing_iterations == 0
          raise StandardError.new('Cannot break outside of a loop!')
        end
        Scope_handler.set_break_flag(true)
        break
      else
        last_stmt = stmt.eval
      end
    end
    last_stmt
  end
end

class List_node
  def initialize(a = nil, b = nil)
    @list = []
    #If 'a' is not nil add elements to 'list'
    if a
      #If 'b' is nil add element 'a' to 'list'
      if b.nil?
        @list << a

      #Else add all elements from list_node 'a' 
      #before adding 'b' to 'list'
      else
        a.get_list.each do |elem|
          @list << elem
        end
        @list << b
      end
    end
  end

  def get_list
    @list
  end

  def unpack_list
    @list.each_with_index do |elem, index|
      if elem.class == List_node
        @list[index] = elem.unpack_list
      end
    end
  end

  def copy(list)
    tmp_list = Array.new
    list.each do |elem|
      tmp_list << elem
    end
    tmp_list
  end

  def evaluate_list(tmp_list)
    tmp_list.each_with_index do |elem, index|
      if elem.class == Array
        tmp_list[index] = evaluate_list(elem)
      else
        tmp_list[index] = elem.eval
      end
    end
    tmp_list
  end

  def eval
    #Unpacks list_nodes so that the list is no longer
    #defined recursively.
    unpack_list()

    #Returns the list if every element is an integer
    if @list.all? {|elem| elem.class == Integer}
      @list
    
    #Else make a copy of the list and return the list
    #with all elements (nodes) in the list evaluated.
    else
      tmp_list = copy(@list)
      evaluate_list(tmp_list)
    end
  end
end

class Run_func_node
  def initialize(name, arg_list = nil)
    @name = name
    @arg_list = arg_list
  end
  
  def eval
    Scope_handler.run_func(@name, @arg_list)
  end
end

class Assign_func_node
  def initialize(name, param_list, block)
    @name = name
    @param_list = param_list
    @block = block
  end

  def eval
    if @param_list.class == List_node
      @param_list = @param_list.eval
    end
    Scope_handler.assign_func(@name, @param_list, @block)
  end
end

class For_node
  def initialize(assign, comp, step, block)
    @assign = assign
    @comp = comp
    @step = step
    @block = block
  end

  def eval
    Scope_handler.add_variable_scope('iteration')
    @assign.eval
    while @comp.eval and (not Scope_handler.get_break_flag and not Scope_handler.get_return_flag)
      @block.eval
      @step.eval unless (Scope_handler.get_break_flag or Scope_handler.get_return_flag)
    end
    Scope_handler.pop_till_scope('iteration')
    Scope_handler.set_break_flag(false)
  end
end

class For_time_node
  def initialize(rel_time, block, step = nil)
    @rel_time = rel_time
    @block = block
    @step = step
  end

  def eval
    if @step and @step.eval > @rel_time.eval
      raise StandardError.new("Step can not be greater than total loop time!, 
        Loop time: '#{@rel_time.eval}', Step: '#{@step.eval}'")
    end

    loop_for = Time.now.to_i + @rel_time.eval
    Scope_handler.add_variable_scope('iteration')
    while Time.now.to_i < loop_for
      @block.eval
      sleep(@step.eval) if @step
    end

    Scope_handler.pop_variable_scope
    Scope_handler.set_break_flag(false)
  end
end

class From_node
  def initialize(s, e, block, step = nil)
    @start = s
    @end = e
    @block = block
    @step = step
  end

  def eval
    @start = @start.eval
    @end = @end.eval

    if @end < @start
      @end += (60 * 60 * 24)
    end
    
    if @step and @step.eval > (@end.to_i - @start.to_i)
      raise StandardError.new("Step can not be greater than total loop time!, 
        Loop time: '#{@rel_time}', Step: '#{@step}'")
    end

    while Time.now < @start
      sleep 1
    end

    Scope_handler.add_variable_scope('iteration')
    while Time.now < @end
      @block.eval
      sleep(@step.eval) if @step
    end
    Scope_handler.pop_variable_scope
    Scope_handler.set_break_flag(false)
  end
end

class At_node
  def initialize(abs_time, block)
    @abs_time = abs_time
    @block = block
  end
  
  def eval
    @abs_time = @abs_time.eval
    while Time.now < @abs_time
      sleep 1
    end
    Scope_handler.add_variable_scope('iteration')
    @block.eval
    @abs_time += (60 * 60 * 24)
    Scope_handler.pop_variable_scope
  end
end

class While_node
  def initialize(comp, block, step=nil)
    @comp = comp
    @block = block
    @step = step
  end

  def eval
    Scope_handler.add_variable_scope('iteration')
    while @comp.eval and (!Scope_handler.get_break_flag and !Scope_handler.get_return_flag)
      @block.eval
      sleep(@step.eval) if @step
    end
    Scope_handler.pop_variable_scope
    Scope_handler.set_break_flag(false)
  end
end

class If_node
  def initialize(boolean_expr, block)
    @boolean_expr = boolean_expr
    @block = block
  end

  def eval
    if @boolean_expr.eval
      Scope_handler.add_variable_scope('if')
      tmp = @block.eval
      Scope_handler.pop_variable_scope
      tmp
    end
  end
end

class If_else_node
  def initialize(*stmts)
    @stmts = stmts.flatten!
  end

  def eval
    @stmts.each do |stmt|
      @tmp = stmt.eval
      break if not @tmp.nil?
    end
    @tmp
  end
end

class Get_list_element_node
  def initialize(var, index)
    @var = var
    @index = index
  end

  def eval
    if @var.class == Get_list_element_node
      @var = @var.eval
    end
  
    if @var.class == Var_node
      list = Scope_handler.get_variable(@var.eval)
    else
      list = @var
    end

    if @index.eval > list.length - 1
      raise IndexError.new("Index out of bounds for #{@var.eval}. '\
                           'Was #{@index}, max #{list.length-1}")
    elsif @index.eval < 0
      raise IndexError.new("Negative index for #{@var.eval}. '\
                            Was #{@index}, must be zero or above")
    end
    list[@index.eval]
  end
end

class Get_var_node
  def initialize(var)
    @var = var
  end

  def get_name
    @var.eval
  end

  def eval
    Scope_handler.get_variable(@var.eval)
  end
end

class Assignment_node
  def initialize(var_name, expr)
    @var_name = var_name
    @expr = expr
  end

  def eval
    Scope_handler.assign_variable(@var_name.eval, @expr.eval)
  end
end

class Shorthand_assignment_node
  def initialize(var, op, expr)
    @var = var
    @op = op
    @expr = expr
  end
  
  def eval
    tmp = Scope_handler.get_variable(@var.eval)
    case @op
      when "+=" then Scope_handler.assign_variable(@var.eval, (tmp + @expr.eval))
      when "-=" then Scope_handler.assign_variable(@var.eval, (tmp - @expr.eval))
      when "*=" then Scope_handler.assign_variable(@var.eval, (tmp * @expr.eval))
      when "/=" then Scope_handler.assign_variable(@var.eval, (tmp / @expr.eval))
    end
  end
end

class Assignment_index_node
  def initialize(list, index, expr)
    @list = list
    @index = index
    @expr = expr
  end

  def eval
    tmp_list = Scope_handler.get_variable(@list.eval)
    tmp_list[@index.eval] = @expr.eval
    Scope_handler.assign_variable(@list.eval, tmp_list)
  end
end

class List_shorthand_assign_node
  def initialize(list, expr)
    @list = list
    @expr = expr
  end

  def eval
    tmp_list = Scope_handler.get_variable(@list.eval)
    if tmp_list.class == Array
      tmp_list << @expr.eval
      Scope_handler.assign_variable(@list.eval, tmp_list)
    else
      raise SyntaxError.new("Variable '#{@list.eval}' is not a list!")
    end
  end
end

class Break_node 
end
 
class Return_node
  def initialize(return_value)
    @return_value = return_value
  end 

  def eval
    @return_value.eval
  end
end

class Input_node
  def eval
    gets.chomp
  end
end

class Nil_node
  def eval
    nil
  end
end

class Or_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def eval
    @a.eval or @b.eval
  end
end

class And_node
  def initialize(a, b)
    @a = a
    @b = b
  end

  def eval
    @a.eval and @b.eval
  end
end

class Not_node
	def initialize(a)
    @a = a
	end

	def eval
    not @a.eval
	end
end

class Comparison_node
  def initialize(a, op, b)
    @a = a
    @op = op
    @b = b
  end
  
  def eval
    begin 
      case @op
        when "<" then @a.eval < @b.eval
        when "<=" then @a.eval <= @b.eval
        when ">" then @a.eval > @b.eval
        when ">=" then @a.eval >= @b.eval
        when "==" then @a.eval == @b.eval
        when "!=" then @a.eval != @b.eval
      end
    rescue
      raise SyntaxError.new("Comparison operator '#{@op}' cannot be used to compare types #{@a.eval.class} and #{@b.eval.class}.")
    end
  end
end

class Boolean_node
  def initialize(a)
    @a = a
  end

  def eval
    @a
  end
end

class Addition_node
	def initialize(a, b)
    @a = a
		@b = b
	end

  def eval
    @a.eval + @b.eval
	end
end

class Subtraction_node
	def initialize(a, b)
    @a = a
    @b = b
	end

	def eval
    @a.eval - @b.eval
	end
end

class Multiplication_node
	def initialize(a, b)
    @a = a
		@b = b
	end

	def eval
    @a.eval * @b.eval
	end
end

class Division_node
	def initialize(a, b)
    @a = a
    @b = b
	end

	def eval
    @a.eval / @b.eval
	end
end

class Power_node
	def initialize(a, b)
    @a = a
    @b = b
	end

	def eval
    @a.eval ** @b.eval
	end
end

class Integer_node
  def initialize(a, neg = nil)
    if neg
      @int = -a
    else
      @int = a
    end
	end

  def eval
    @int
	end
end

class Float_node
  def initialize(a, neg = nil)
    if neg
      @float = -a
    else
      @float = a
    end
	end

	def eval
    @float
	end
end

class String_node
  def initialize(a)
    @string = a
	end

  def eval
    @string
	end
end

class Rel_time_node
  def initialize(hours:nil, minutes:nil, seconds:nil)
    @hours = hours ? hours.split('h')[0].to_i : 0
    @minutes = minutes ? minutes.split('m')[0].to_i : 0
    @seconds = seconds ? seconds.split('s')[0].to_i : 0
  end
  
  def eval
    (@hours * 3600 + @minutes * 60 + @seconds)
  end
end

class Abs_time_node
  def initialize(time)
    @time = time
  end

  def eval
    start = Time.now
    hours, minutes, seconds = @time.split(':')
    hours, minutes, seconds = hours.to_i, minutes.to_i, seconds.to_i
    skip_day = false

    #Creates a time object coresponding to inputed hours, minutes and seconds
    @time = Time.new(Time.now.year, Time.now.month, Time.now.day, hours, minutes, seconds)
    
    #Checks if specified time has already occured today
    #and if so add an extra 24h to the time
    if hours < start.hour
      skip_day = true
    elsif hours == start.hour
      if minutes < start.min
        skip_day = true
      elsif minutes == start.min
        if seconds < start.sec
          skip_day = true
        end
      end
    end

    if skip_day == true
      @time += (60 * 60 * 24)
    end

    @time
  end
end

class Var_node
  def initialize(name)
    @name = name
	end

	def eval
		@name
	end
end