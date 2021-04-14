require 'test/unit'
require_relative 'timescript.rb'
require_relative 'scope_handler.rb'

class Test_class < Test::Unit::TestCase
  def test_functions
    t = TimeScript.new
    t.log(false)
    breakTest =
"-10**-3"
  #printen på detta test borde bli 999! (tester går alltid igenom!)
    #assert_raise SyntaxError do
    assert_equal(-0.001, t.parse_line(breakTest))
    #end
  end
end