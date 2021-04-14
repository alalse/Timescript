#!/usr/bin/env ruby
$install_directory = ''

require 'pathname'

if $install_directory != ''
  if Pathname($install_directory).exist?
    require $install_directory + 'rdparse.rb'
    require $install_directory + 'nodes.rb'
  else
    raise LoadError.new("Invalid install directory!")
  end
else
  if Pathname(Dir.pwd).each_child(false).any? {|f| f.basename.to_s == 'timescript.rb'}
    require_relative 'rdparse.rb'
    require_relative 'nodes.rb'
  else
    raise LoadError.new("No timescript files found in this folder!")
  end
end

class String_token
  attr_accessor :string
  def initialize(a)
    @string = a
    @string[0] = ''
    @string[@string.length - 1] = ''
  end
end

class Abs_time_token
  attr_accessor :time
  def initialize(time)
    @time = time
  end
end

class TimeScript
  def initialize
    @scriptParser = Parser.new("TimeScript") do
      @indent_stack = [0]

      #Pia Lötvedt's indentation code
      token(/\s*\n[ \t]*/) do |m|
        indent_size = m[/\s*\n\K[ \t]*/].gsub("\t", " "*4).size
        if indent_size == @indent_stack.last
          # Only newline if same as previous indent
          next :newline
        elsif indent_size > @indent_stack.last
          @indent_stack << indent_size
          # Newline followed by indent if larger than previous indent
          next [:newline, :indent]
        else
          dedents = [:newline]
          loop do
            @indent_stack.pop
            dedents << :dedent
            break if indent_size == @indent_stack.last
            # Ensures dedents goes back to an existant indendation level
            # (Maybe better with a custom error here, as its not a Ruby-SyntaxError)
            raise SyntaxError, "Bad indentation" if indent_size > @indent_stack.last
          end
          # Newline followed by a number of dedents if lesser than previous indent
          next dedents
        end
      end
      
      token(/(\".*\"|\'.*\')/) {|m| String_token.new(m)}
      token(/\s/)
      token(/\d{2}:\d{2}:\d{2}/) {|m| Abs_time_token.new(m)}
      token(/\d+[hms]/) {|m| m}
      token(/\d+\.\d+/) {|m| m.to_f}
      token(/\d+/) {|m| m.to_i}
      token(/\w+/) {|m| m}
      token(/(==|!=|<=|>=|\*\*|\+=|-=|\*=|\/=|<<)/) {|m| m}
      token(/./) {|m| m}

      start :program do
        match(:statement_list) {|a| Program_node.new(a).eval}
      end

      rule :statement_list do
        match(:statement_list, :line) {|a, b| Statement_list_node.new(a, b)}
        match(:line) {|a| Statement_list_node.new(a)}
      end

      rule :line do
        match(:statement, :newline)
        match(:statement)
      end

      rule :statement do
        match(:return)
        match(:break)
        match(:function)
        match(:at_stmt)
        match(:while_loop)
        match(:from_loop)
        match(:for_loop)
        match(:if_else_stmt)
        match(:assignment)
        match(:expr)
      end 

      rule :param_list do
        match(:param_list, ',', String) {
          |a, _, b| List_node.new(a, String_node.new(b))}
        match(String) {|a| List_node.new(String_node.new(a))}
      end

      rule :arg_list do
        match(:arg_list, ',', :expr) {|a, _, b| List_node.new(a, b)}
        match(:expr) {|a| List_node.new(a)}
      end

      rule :function do
        match('def', String, '(', :param_list, ')', :indented_block) {
          |_, name, _, param_list, _, block| 
          Assign_func_node.new(name, param_list, block)}
        match('def', String, '(', ')', :indented_block) {
          |_, name, _, _, block| Assign_func_node.new(name, param_list = nil, block)}
      end

      rule :function_call do
        match(/\w+/, '(', :arg_list, ')') {
          |name, _, arg_list| Run_func_node.new(name, arg_list)}
        match(/\w+/, '(', ')') {|name| Run_func_node.new(name)}
      end

      rule :at_stmt do
        match('at', :abs_time, :indented_block) {
          |_, abs_time, block| At_node.new(abs_time, block)}
      end

      rule :from_loop do
        match('from', :abs_time, 'to', :abs_time, 'each', :rel_time, :indented_block) {
          |_, abs_time_start, _, abs_time_end, _, step, block| 
          From_node.new(abs_time_start, abs_time_end, block, step)}
        match('from', :abs_time, 'to', :abs_time, :indented_block) {
          |_, abs_time_start, _, abs_time_end, block| 
          From_node.new(abs_time_start, abs_time_end, block)}
      end

      rule :for_loop do
        match('for', :rel_time, 'each', :rel_time, :indented_block) {
          |_, rel_time, _, step, block| For_time_node.new(rel_time, block, step)}
        match('for', :rel_time, :indented_block) {
          |_, rel_time, block| For_time_node.new(rel_time, block)}
        match('for', :assignment, ',', :comparison, ',', :assignment, :indented_block) {
          |_, assign, _, comp, _, step, block| For_node.new(assign, comp, step, block)}
      end
       
      rule :rel_time do
        match(/\d+h/, /\d+m/, /\d+s/) {|h, m, s| 
          Rel_time_node.new(hours:h, minutes:m, seconds:s)}
        match(/\d+h/, /\d+m/) {|h, m| Rel_time_node.new(hours:h, minutes:m)}
        match(/\d+h/, /\d+s/) {|h, s| Rel_time_node.new(hours:h, minutes:nil, seconds:s)}
        match(/\d+m/, /\d+s/) {|m, s| Rel_time_node.new(minutes:m, seconds:s)}
        match(/\d+h/) {|h| Rel_time_node.new(hours:h)}
        match(/\d+m/) {|m| Rel_time_node.new(minutes:m)}
        match(/\d+s/) {|s| Rel_time_node.new(seconds:s)}
      end

      rule :abs_time do
        match(Abs_time_token) {|a| Abs_time_node.new(a.time)}
      end

      rule :while_loop do
        match('while', :boolean_expr, 'each', :rel_time, :indented_block) {
          |_, comp, _, step, block| While_node.new(comp, block, step)}
        match('while', :boolean_expr, :indented_block) {|_, comp, block| 
          While_node.new(comp, block)}
      end

      rule :if_else_stmt do
        match(:if_stmt, :elsif_stmt, :else_stmt) {|a, b, c| If_else_node.new(a, b, c)}
        match(:if_stmt, :elsif_stmt) {|a, b| If_else_node.new(a, b)}
        match(:if_stmt, :else_stmt) {|a, b| If_else_node.new(a, b)}
        match(:if_stmt)
      end

      rule :if_stmt do
        match('if', :boolean_expr, :indented_block) {
          |_, boolean_expr, block| If_node.new(boolean_expr, block)}
      end

      rule :elsif_stmt do
        match('elsif', :boolean_expr, :indented_block, :elsif_stmt) do 
          |_, boolean_expr, block, if_list|
          if_list << If_node.new(boolean_expr, block)
        end
        match('elsif', :boolean_expr, :indented_block) {
          |_, boolean_expr, block| [If_node.new(boolean_expr, block)]}
      end

      rule :else_stmt do
        match('else', :indented_block) {
          |_, block| [If_node.new(Boolean_node.new(true), block)]}
      end

      rule :indented_block do
        match(:newline, :indent, :statement_list, :newline, :dedent) {
          |_, _, stmt_list, _, _| stmt_list}
        match(:newline, :indent, :statement_list, :dedent) {
          |_, _, stmt_list, _| stmt_list}
        match(:newline, :indent, :statement_list) {|_, _, stmt_list| stmt_list}
      end

      rule :assignment do
        match(:var, '[', :arithmetic_expr, ']', '=', :expr) {
          |var, _, index, _, _, b| Assignment_index_node.new(var, index, b)}
        match(:var, '=', :expr) {|a, _, b| Assignment_node.new(a, b)}
        match(:var, :shorthand_op, :expr) {|a, op, b| 
          Shorthand_assignment_node.new(a, op, b)}
      end

      rule :shorthand_op do
        match('+=')
        match('-=')
        match('*=')
        match('/=')
      end
      
      rule :expr do
        match(:nil)
        match(:input)
        match(:list)
        match(:list_shorthand_add)
        match(:boolean_expr)
        match(String_token) {|st| String_node.new(st.string)}
      end

      rule :break do
        match('break') {Break_node.new()}
      end

      rule :return do
        match('return', :expr) {|_, expr| Return_node.new(expr)}
      end
      
      rule :nil do
        match('nil') {Nil_node.new()}
      end

      rule :input do
        match('input') {Input_node.new()}
      end

      rule :list do
        match('[', :arg_list, ']') {|_, list, _| list}
        match('[', ']') {List_node.new()}
      end

      rule :list_shorthand_add do
        match(:var, '<<', :expr) {|var, _, expr| List_shorthand_assign_node.new(var, expr)}
      end

      rule :boolean_expr do
        match(:boolean_expr, 'or', :boolean_term) {|a, _, b| Or_node.new(a, b)}
        match(:boolean_term)
      end

      rule :boolean_term do
        match(:boolean_term, 'and', :boolean_factor) {|a, _, b| And_node.new(a, b)}
        match(:boolean_factor)
      end

      rule :boolean_factor do
        match('not', :boolean_factor) {|_, a| Not_node.new(a)}
        match('true') {Boolean_node.new(true)}
        match('false') {Boolean_node.new(false)}
        match(:comparison)
      end

      rule :comparison do
        match(:arithmetic_expr, :comp_op, :arithmetic_expr) {
          |a, op, b| Comparison_node.new(a, op, b)}
        match(:arithmetic_expr)
      end

      rule :comp_op do
        match('<')
        match('<=')
        match('>')
        match('>=')
        match('==')
        match('!=')
      end
        
      rule :arithmetic_expr do 
        match(:arithmetic_expr, '+', :arithmetic_term) {
          |a, _, b| Addition_node.new(a, b)}
        match(:arithmetic_expr, '-', :arithmetic_term) {
          |a, _, b| Subtraction_node.new(a, b)}
        match(:arithmetic_term)
      end
        
      rule :arithmetic_term do 
        match(:arithmetic_term, '*', :arithmetic_factor) {
          |a, _, b| Multiplication_node.new(a, b)}
        match(:arithmetic_term, '/', :arithmetic_factor) {
          |a, _, b| Division_node.new(a, b)}
        match(:arithmetic_factor)
      end

      rule :arithmetic_factor do
        match(:arithmetic_primary, '**', :arithmetic_factor) {
          |a, _, b| Power_node.new(a, b)}
        match(:arithmetic_primary)
      end

      rule :arithmetic_primary do
        match('(', :boolean_expr, ')') {|_, a, _| a}
        match(:integer)
        match(:float)
        match(:list_var)
        match(:function_call)
        match(:var) {|a| Get_var_node.new(a)}
      end

      rule :list_var do
        match(:list_var, '[', :arithmetic_expr, ']') {
          |var, _, index, _| Get_list_element_node.new(var, index)}
        match(:var, '[', :arithmetic_expr, ']') {
          |var, _, index, _| Get_list_element_node.new(var, index)}
      end

      rule :var do
        match(String) {|var| Var_node.new(var)}
      end

      rule :integer do
        match('-', Integer) {|neg, a| Integer_node.new(a, neg)}
        match(Integer) {|a| Integer_node.new(a)}
      end

      rule :float do
        match('-', Float) {|neg, a| Float_node.new(a, neg)}
        match(Float) {|a| Float_node.new(a)}
      end
    end
  end

  def done(str)
    ["quit","exit",""].include?(str.chomp)
  end
        
  def run
    @scriptParser.parse "lista = [1, 2, 3]"
    str = gets
    if done(str) then
      puts "Bye."
    else
      puts "=> #{@scriptParser.parse str}"
      run
    end
  end

  def parse_line(str)
    @scriptParser.parse str
  end

  def log(state = true)
    @scriptParser.logger.level = state ? Logger::DEBUG : Logger::WARN
  end
end

t = TimeScript.new()
Scope_handler.initialize
t.log(false)

if ARGV.length == 0
  puts "[TimeScript]"
  t.run
elsif ARGV.length == 1
  file = File.read(ARGV[0])
  t.parse_line(file)
else
  warn("WARNING, Timescript only accepts a single command line argument, 
        arguments after the first one are ignored!")
end