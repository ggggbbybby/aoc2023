input = File.read("input1.txt")
test = <<TXT
1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet
TXT

test2 = <<TXT
two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
eighthree
sevenine
TXT

class CalibrationValues
  def total(lines)
    words = lines.split("\n")
    words.map { |w| first_and_last_digit(w).join("").to_i }.sum
  end

  def first_and_last_digit(word)
    matches = word.scan(/\d/)
    [matches.first, matches.last]#.tap { |out| p out }
  end

  def total2(lines)
    words = lines.split("\n")
    words.map { |w| first_and_last_digit2(w).join("").to_i }.sum
  end

  # some spelled-out digits can share a letter, like "eighthree" should be 8 and 3 not just 8
  # this is very hard to regexp out of, so we're going with something stupider and easier to read
  # these "swaps" preserve the first and last letter but adds a digit we can scan for.
  SWAPS = {
    "one" => "o1e",
    "two" => "t2o",
    "three" => "t3e",
    "four" => "f4r",
    "five" => "f5e",
    "six" => "s6x",
    "seven" => "s7n",
    "eight" => "e8t",
    "nine" => "n9e"
  }

  def first_and_last_digit2(word)
    matches = SWAPS.inject(word) { |iter, (k, v)| iter.gsub(k, v) }.scan(/\d/)
    [matches.first, matches.last].map(&:to_i)#.tap { |out| p [word, matches, out.join("").to_i] }
  end

end

puts "Part 1"
puts "Test: #{CalibrationValues.new.total(test)}"
puts "Input: #{CalibrationValues.new.total(input)}"

puts "Part 2"
puts "Test: #{CalibrationValues.new.total2(test2)}"
puts "Input: #{CalibrationValues.new.total2(input)}"