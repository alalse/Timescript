require_relative 'functions.rb'

class Scope_handler
  @@variables = Array.new
  @@variables << Hash.new
  @@reserved_symbols = ['true', 'false', 'if', 'elsif', 'else', 'def', 'break', 
                        'return', '==', '!=', '<=', '>=', '**', '+=', '-=', 
                        '*=', '/=', '0DQdhzc2x8']
  @@functions = Hash.new
  @@reserved_functions = Array.new
  @@ongoing_function_calls = {ongoing: 0, return_value: nil, return_flag: false}
  @@ongoing_iterations = {ongoing: 0, break_flag: false}

  #Adds all predefined functions from Timescript to @@reserved_functions
  def Scope_handler.initialize
    IO.foreach($install_directory + 'functions.rb') do |line|
      if line =~ /def\s(\w+)/
        @@reserved_functions << $1
      end
    end
  end

  #Getters and setters for handling breaks and returns

  def Scope_handler.get_ongoing_function_calls
    @@ongoing_function_calls[:ongoing]
  end

  def Scope_handler.get_return_flag
    @@ongoing_function_calls[:return_flag]
  end

  def Scope_handler.get_return_value
    @@ongoing_function_calls[:return_value]
  end

  def Scope_handler.set_return_flag(boolean)
    @@ongoing_function_calls[:return_flag] = boolean
  end

  def Scope_handler.get_ongoing_iterations
    @@ongoing_iterations[:ongoing]
  end

  def Scope_handler.get_break_flag
    @@ongoing_iterations[:break_flag]
  end

  def Scope_handler.set_break_flag(boolean)
    @@ongoing_iterations[:break_flag] = boolean
  end

  def Scope_handler.set_return_value(value)
    @@ongoing_function_calls[:return_value] = value
  end

  #Adds a new variable scope to the end of @@variables
  def Scope_handler.add_variable_scope(type, scope = nil)
    @@ongoing_iterations[:ongoing] += 1
    new_scope = Hash.new

    #Copies over each variable from the last scope to the new one
    @@variables.last().each do |key, value|
      new_scope[key] = value
    end
    new_scope['0DQdhzc2x8'] = type
    @@variables << new_scope

    #Adds incoming variables to new scope
    if scope
      scope.each do |key, value|
        @@variables.last()[key] = value
      end
    end
  end

  #Adds a new function scope to the end of @@variables
  def Scope_handler.add_function_scope(scope = nil)
    @@ongoing_function_calls[:ongoing] += 1
    new_scope = Hash.new
    new_scope['0DQdhzc2x8'] = "func"

    #Adds incoming variables to the new scope
    if scope
      scope.each do |key, value|
        new_scope[key] = value
      end
    end
    @@variables << new_scope
  end

  #Removes the last scope, only call if the current last 
  #scope is a variable scope.
  def Scope_handler.pop_variable_scope
    #Pop the last scope and transfer the value of all variables whose name
    #also exists in the new last scope
    old_scope = @@variables.pop()
    @@variables.last().each do |key, value|
      if @@variables.last().key?(key) and old_scope[key] != value and key != '0DQdhzc2x8'
        @@variables.last()[key] = old_scope[key]
      end
    end
    old_scope
  end

  #Removes the last scope, only call if the current last 
  #scope is a function scope.
  def Scope_handler.pop_function_scope
    @@variables.pop()
  end

  #Pops scopes until the new last scope equals 'type' or until there is
  #only one scope left.
  def Scope_handler.pop_till_scope(type)
    loop do
      if @@variables.length == 1
        break
      end
      if @@variables.last()['0DQdhzc2x8'] == 'func'
        old_scope = Scope_handler.pop_function_scope
        @@ongoing_function_calls[:ongoing] -= 1
      else
        old_scope = Scope_handler.pop_variable_scope
        @@ongoing_iterations[:ongoing] -= 1
      end

      if old_scope['0DQdhzc2x8'] == type
        break
      end
    end
  end
 
  #Assigns a variable to current scope in @@variables
  def Scope_handler.assign_variable(name, data)
    if not @@reserved_symbols.include?(name)
      @@variables.last()[name] = data
    else
      raise SyntaxError.new("Cannot assign to reserved symbols!")
    end
  end

  #Gets value from variable 'name' in current scope.
  #Raises error if variable does not exist.
  def Scope_handler.get_variable(name)
    if @@variables.last().include?(name)
      @@variables.last()[name]
    else
      raise SyntaxError.new("Variable '#{name}' does not exist!")
    end
  end

  #Assigns a function to @@functions
  def Scope_handler.assign_func(name, param_list, block)
    @@functions[name] = {parameters: param_list, block: block}
  end

  #Runs a called function and return a value if the function returned a value.
  def Scope_handler.run_func(name, arg_list=nil)
    #If the called function is a predefined/built-in function of the language
    if @@reserved_functions.include?(name)
      #If the function has parameters
      if arg_list.class == List_node
        arg_list = arg_list.eval
        eval "#{name}(#{arg_list})"
      #Function has no parameters
      else
        eval "#{name}()"
      end

    #If the called function is included in @@functions/is defined by a user
    elsif @@functions.include?(name)
      func = @@functions[name]
      #If the function has parameters
      if func[:parameters]
        param_list = func[:parameters]

        #Combine param and arg list
        if arg_list.class == List_node
          arg_list = arg_list.eval
        end
        if param_list.length != arg_list.length
          raise SyntaxError.new("Wrong amount of arguments. '\
          'Got #{arg_list.length}, should be #{param_list.length}")
        end
        param_arg_list = Hash.new
        param_list.each_with_index do |v, i|
          param_arg_list[v] = arg_list[i]
        end
        
        #Add function scope with param_arg_list
        Scope_handler.add_function_scope(param_arg_list)
      else
        #Add empty function scope
        Scope_handler.add_function_scope()
      end

      #Run the function and then pop scopes until the called functions
      #function scope gets popped.
      func[:block].eval
      Scope_handler.pop_till_scope('func')

      #Gets and returns the function's return value
      @@ongoing_function_calls[:return_flag] = nil
      tmp = @@ongoing_function_calls[:return_value]
      @@ongoing_function_calls[:return_value] = nil
      tmp
    else
      raise SyntaxError.new("Function '#{name}' does not exist!")
    end
  end
end