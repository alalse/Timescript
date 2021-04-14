require 'test/unit'
require_relative 'timescript.rb'
require_relative 'scope_handler.rb'

class Test_class < Test::Unit::TestCase
  
    def test_boolean_expressions
      t = TimeScript.new
      t.log(false)
      assert_equal(false, t.parse_line("false"))
      assert_equal(true, t.parse_line("true"))

      assert_equal(true, t.parse_line("true or true"))
      assert_equal(true, t.parse_line("true or false"))
      assert_equal(true, t.parse_line("false or true"))
      assert_equal(false, t.parse_line("false or false"))
      
      assert_equal(true, t.parse_line("true and true"))
      assert_equal(false, t.parse_line("true and false"))
      assert_equal(false, t.parse_line("false and true"))
      assert_equal(false, t.parse_line("false and false"))

      assert_equal(false, t.parse_line("not true"))
      assert_equal(true, t.parse_line("not false"))

      t.parse_line("x = false")
      t.parse_line("y = true")
      assert_equal(false, t.parse_line("x"))
      assert_equal(true, t.parse_line("y"))

      assert_equal(true, t.parse_line("not x"))
      assert_equal(false, t.parse_line("not y"))
      assert_equal(true, t.parse_line("x or y"))
      assert_equal(false, t.parse_line("x and y"))
    end

    def test_complex_boolean_expressions
      t = TimeScript.new
      t.log(false)
      t.parse_line("x = true")
      assert_equal(true, t.parse_line("(true and true) and (false or true)"))
      assert_equal(true, t.parse_line("((not true) or x) and ((not (true and false)) and (true or false))"))
    end

    def test_arithmetic_expressions
      t = TimeScript.new
      t.log(false)
      #Basic arithmetic
      assert_equal(2, t.parse_line("1 + 1"))
      assert_equal(1, t.parse_line("2 - 1"))
      assert_equal(1, t.parse_line("2-1"))
      assert_equal(1, t.parse_line("2- 1"))
      assert_equal(1, t.parse_line("2 -1"))
      assert_equal(4, t.parse_line("2 * 2"))
      assert_equal(6, t.parse_line("12 / 2"))
      assert_equal(8, t.parse_line("2 ** 3"))
      assert_equal(3, t.parse_line("9 ** 0.5"))

      #Paranthesis and chained operations
      assert_equal(5, t.parse_line("(5)"))
      assert_equal(14, t.parse_line("(7 + 7)"))
      assert_equal(15, t.parse_line("5 + (3 + 7)"))
      assert_equal(40, t.parse_line("(2 + 2) * 10"))
      assert_equal(30, t.parse_line("(10 + 10) + (3 + 7)"))
      assert_equal(100, t.parse_line("(3 + 7) ** 2"))
      assert_equal(22, t.parse_line("2 + 2 * 10"))
      assert_equal(4, t.parse_line("1 + 1 + 1 + 1"))
      
      #Arithmetic with variables
      t.parse_line("x = 10")
      assert_equal(10, t.parse_line("x"))
      assert_equal(15, t.parse_line("x + 5"))
      t.parse_line("x = x + 10")
      assert_equal(20, t.parse_line("x"))
      t.parse_line("x = 5 + 10")
      assert_equal(15, t.parse_line("x"))
      t.parse_line("x = 10")
      t.parse_line("x += 10")
      assert_equal(20, t.parse_line("x"))
      t.parse_line("x -= 10")
      assert_equal(10, t.parse_line("x"))
      t.parse_line("x *= 2")
      assert_equal(20, t.parse_line("x"))
      t.parse_line("x /= 2")
      assert_equal(10, t.parse_line("x"))      

      #Floats and negatives
      assert_equal(-1, t.parse_line("1 - 2"))
      assert_equal(1, t.parse_line("2.0 - 1"))
      assert_equal(1, t.parse_line("2-1.0"))
      assert_equal(1, t.parse_line("2.0- 1"))
      assert_equal(1, t.parse_line("2 -1.0"))
      assert_equal(1.5, t.parse_line("2 - 0.5"))
      assert_equal(10, t.parse_line("5 / 0.5"))
      assert_equal(2, t.parse_line("5 / 2"))
      assert_equal(2.5, t.parse_line("5.0 / 2"))
      assert_equal(4.6, t.parse_line("2.3 * 2"))

      assert_equal(-10, t.parse_line("5 * -2"))
      assert_equal(-3, t.parse_line("-5 - -2"))
      assert_equal(3, t.parse_line("5 + -2"))
    end

    def test_comparisons
      t = TimeScript.new
      t.log(false)
      assert_equal(true, t.parse_line("1 < 2"))
      assert_equal(true, t.parse_line("5 > 1"))
      assert_equal(true, t.parse_line("2 <= 2"))
      assert_equal(false, t.parse_line("1 >= 2"))
      assert_equal(false, t.parse_line("10 != 10"))
      assert_equal(true, t.parse_line("9 == 9"))
    end

    def test_complex_comparisons
      t = TimeScript.new
      t.log(false)
      assert_equal(true, t.parse_line("1 + 1 == 1 + 1"))
      assert_equal(true, t.parse_line("2 * 2 < 10 - 1"))
      assert_equal(true, t.parse_line("2 ** 4 == 64 - 16 * 3"))
      assert_equal(true, t.parse_line("1 + 16 == (64 - 16 * 3) + 1"))

      
      t.parse_line("x = 16 + 4 ** 0.5")
      assert_equal(true, t.parse_line("13 != 14 and (x * 2) / 4 == 9"))
    end

    def test_string
      t = TimeScript.new
      t.log(false)
      
      t.parse_line("string1 = 'hej'")
      assert_equal("hej", t.parse_line("string1"))
      t.parse_line('string2 = "hej"')
      assert_equal("hej", t.parse_line("string2"))
      t.parse_line('string3 = "x = 1"')
      assert_equal("x = 1", t.parse_line("string3"))
      t.parse_line('string4 = "abc\n123"')
      assert_equal("abc\\n123", t.parse_line("string4"))
    end
    
    def test_list
      t = TimeScript.new
      t.log(false)
      
      #index testing
      t.parse_line("list = [1]")
      assert_equal(1, t.parse_line("list[0]"))
      t.parse_line("list = [9, 4, 7]")
      assert_equal(9, t.parse_line("list[0]"))
      assert_equal(4, t.parse_line("list[1]"))
      assert_equal(7, t.parse_line("list[2]"))
      assert_raise IndexError do
        t.parse_line("list[3]")
      end
      assert_raise IndexError do
        t.parse_line("list = [9, 4, 7]")
        t.parse_line("list[-1]")
      end

      #assignment and comparison
      t.parse_line("a = list[1]")
      assert_equal(4, t.parse_line("a"))
      t.parse_line("list[1] = 5")
      assert_equal(5, t.parse_line("list[1]"))
      t.parse_line("list2 = [9, 2, 14]")
      assert_equal(true, t.parse_line("list[0] == list2[0]"))
      assert_equal(false, t.parse_line("list[1] == list2[1]"))
      t.parse_line("list[2] = list2[2]")
      assert_equal(14, t.parse_line("list[2]"))

      t.parse_line("xyz = 1")
      assert_equal(5, t.parse_line("list[xyz]"))
      assert_equal(14, t.parse_line("list[3 - 1]"))
      t.parse_line("xyz = -2")
      assert_raise IndexError do
        t.parse_line("list[xyz]")
      end

      #list in list
      t.parse_line("list3 = [1, [[1, 2], 7, 8], 2]")
      assert_equal(2, t.parse_line("list3[1][0][1]"))

      #list in if
      if_stmtList = 
"listIf = [4, 7, 9]
if true
  listIf[2] = 2
  listIf[1] = listIf[2]
listIf[1] + listIf[2]
"
      assert_equal(4, t.parse_line(if_stmtList))
      funcList = 
"listFunc = [1, 2, 3, 4, 5]
def funcList(l)
  return l[4] + 10
funcList(listFunc)
listFunc[1] + listFunc[4]
"
      assert_equal(7, t.parse_line(funcList))
      
      funcList2 = 
"listFunc = [1, 2, 3, 4, 5]
def funcList2(l)
  l[4] = 15
  return l
funcList2(listFunc)
listFunc[1] + listFunc[4]
"
      assert_equal(17, t.parse_line(funcList2))
    end

    def test_if_statement
      t = TimeScript.new
      t.log(false)
      if_stmt1 = 
"if 1 == 1
  x = 2
  x + 7
"
      assert_equal(9, t.parse_line(if_stmt1))

      if_stmt2 = 
"if 1 == 2
  3 + 3
"
      assert_equal(nil, t.parse_line(if_stmt2))

      if_stmt3 = 
"x = false
if not x
  5 + 10
"
      assert_equal(15, t.parse_line(if_stmt3))

      if_stmt4 = 
"y = 10
if 1 == 1
  y + 11
"
      assert_equal(21, t.parse_line(if_stmt4))

      if_stmt5 = 
"if 1 == 1
  if 2 + 2 == 4
    7 + 2
"     
      assert_equal(9, t.parse_line(if_stmt5))

      if_stmt6 = 
"if 1 == 1
  if 2 + 2 == 4
    7 + 2
  9 + 7
"     
      assert_equal(16, t.parse_line(if_stmt6))

      if_stmt7 = 
"if 1 == 1
  x = 2 + 2
if 2 + 2 == 4
  x + 2
"     
      assert_equal(6, t.parse_line(if_stmt7))

      if_stmt8 = 
"if false
  2 + 2
elsif true
  3 + 2
"     
      assert_equal(5, t.parse_line(if_stmt8))

      if_stmt9 = 
"if false
  2 + 2
else
  3 + 7
"     
      assert_equal(10, t.parse_line(if_stmt9))

      if_stmt10 = 
"if false
  2 + 2
elsif false
  4 + 4
else
  7 + 7
"     
      assert_equal(14, t.parse_line(if_stmt10))

      if_stmt11 = 
"if false
  2 + 2
elsif false
  4 + 4
elsif true
  7 + 10
"     
      assert_equal(17, t.parse_line(if_stmt11))

      if_stmt12 = 
"if false
  2 + 2
elsif false
  4 + 4
elsif true
  7 + 10
else
  1 + 1
"     
      assert_equal(17, t.parse_line(if_stmt12))

      if_stmt13 = 
"if false
  2 + 2
elsif false
  4 + 4
elsif true
  if false
    1 + 1
  elsif true
    8 + 8
"
      assert_equal(16, t.parse_line(if_stmt13))

      if_stmt14 = 
"if false
  2 + 2
elsif false
  4 + 4
elsif true
  if false
    1 + 1
  elsif false
    8 + 8
else
  10 + 10
"
      assert_equal(20, t.parse_line(if_stmt14))

      if_stmt15 = 
"if = 10
if if == 10
  100 + 5
"
      assert_raise SyntaxError do 
        t.parse_line(if_stmt15)
      end

      if_stmt16 = 
"if 1 == 1
if 10 == 10
  1 + 5
"
      assert_raise SyntaxError do
        t.parse_line(if_stmt16)
      end

      if_stmt18 =
"x = 10
if 1 == 1
  x = 20
x + 3"
      assert_equal(23, t.parse_line(if_stmt18))
        
    end

    def test_functions
      t = TimeScript.new
      t.log(false)
      func1 = 
"def func1()
  return 4 + 4
func1()
"
      assert_equal(8, t.parse_line(func1))

      func2 = 
"def func2(hej)
  return hej + 4
func2(5)
"
      assert_equal(9, t.parse_line(func2))

      func3 = 
"def func3(hej, tja)
  return hej / tja
func3(10, 2)
"
      assert_equal(5, t.parse_line(func3))

func4 = 
"def func4(hej, tja)
  return hej / tja
func4(10, 2, 7)
"
      assert_raise SyntaxError do
        t.parse_line(func4)
      end

      func5 = 
"def func5(hej, tja, sol)
  return hej / tja
func5(10, 2)
"
      assert_raise SyntaxError do
        t.parse_line(func5)
      end

      func6 = 
"def funcOut(hej, tja)
  hej / tja
  def funcIn()
    return 5 + 5
  return funcIn()
funcOut(10, 2)
"
      assert_equal(10, t.parse_line(func6))
      funcRec = 
"def funcRec(i)
  if i < 3
    i = i + 1
    return funcRec(i)
  else
    return i
funcRec(0)
"
      assert_equal(3, t.parse_line(funcRec))

      funcRec2 = 
"def funcRec(i)
  if i < 10
    i = i + 2
    return funcRec(i)
  else
    return i
i = 0
funcRec(i)
"
      assert_equal(10, t.parse_line(funcRec2))

      funcFunc = 
"def funcF1(par)
  return par + 5

def funcF2(par)
  return funcF1(par + 3)

def funcF3()
  return funcF2(0)

funcF3()
"
      assert_equal(8, t.parse_line(funcFunc))

      funcIf = 
"def funcIf(x, y, z)
  return x + y * z

x = 5
y = 10
z = 1

if x > y
  funcIf(x, y, z)
else
  z = 3
  funcIf(x, y, z)
"
      assert_equal(35, t.parse_line(funcIf))

      funcLoop = 
"def funcLoop(x)
  for i = 0, i < 5, i += 1
    if i == 3
      return x
    x += 1
funcLoop(4)
"
      assert_equal(7, t.parse_line(funcLoop))

      funcLoop2 = 
"def funcLoop2(x)
  b = false
  for i = 0, i < 5, i += 1
    print(i)
    if i == 3
      b = true
    if b == (true)
      return i
funcLoop2(4)
"
      assert_equal(3, t.parse_line(funcLoop2))

    end

    def test_loops
      t = TimeScript.new
      t.log(false)
      for_1 = 
"a = 0
for x = 0, x < 10, x = x + 1
  a = x
a
"
      assert_equal(9, t.parse_line(for_1))
      for_2 = 
"a = 0
for x = 0, x <= 1000, x = x + 1
  a = x
a
"
      assert_equal(1000, t.parse_line(for_2))
      for_3 = 
"a = 0
for x = 10, x < 5, x = x + 1
  a = x
a
"
      assert_equal(0, t.parse_line(for_3))
      for_4 = 
"a = 0
b = 10
for x = 0, x < b, x = x + 2
  a = x
  b = b + 1
a
"
      assert_equal(18, t.parse_line(for_4))
    end

end