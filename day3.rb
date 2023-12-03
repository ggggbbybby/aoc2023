input = File.read("input3.txt")
test = <<TXT
467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..
TXT

class SchematicParser
  def initialize(schematic)
    # lets make a 2D array to make search "easy"
    @schematic = schematic.split("\n").map(&:chars)
  end

  # handle the bit-by-bit search, yielding coords & current value for each pixel in the schematic
  def search
    @schematic.each_with_index do |row, row_idx|
      row.each_with_index do |px, col_idx|
        yield [px, row_idx, col_idx]
      end
    end
  end

  def part_numbers
    numbers = []
    current_number = ""
    is_adjacent = false

    search do |px, row_idx, col_idx|
      if px =~ /\d/
        current_number << px
        is_adjacent ||= symbol_adjacent_coords?(row_idx, col_idx)
      elsif !current_number.empty?
        # we have moved to a 'not a digit' char so write the current number to the list if it belongs there
        # and reset so we can continue looking
        # p "#{current_number} is adjacent? #{is_adjacent}"
        numbers << current_number.to_i if is_adjacent
        current_number = ""
        is_adjacent = false
      else
        # nothing happens here, I think
        # we're in an empty state, and we can move on to the next pixel
      end
    end

    return numbers
  end

  # we need to do the same thing we did with part numbers but we need to track which symbol goes with which numbers
  # symbols aren't unique, so we'll keep track of them via their positions (there may be > 1 gear)
  def gears
    numbers = {}
    current_number = ""
    adjacent_gear_coords = nil

    search do |px, row_idx, col_idx|
      if px =~ /\d/
        current_number << px
        adjacent_gear_coords ||= adjacent_gear_coords(row_idx, col_idx)
      elsif !current_number.empty?
        numbers[adjacent_gear_coords] ||= []
        numbers[adjacent_gear_coords] << current_number.to_i
        current_number = ""
        adjacent_gear_coords = nil
      end
    end
    return numbers
  end

  def combined_gear_ratio
    gears.inject(0) do |total, (_coords, part_numbers)|
      part_numbers.length == 2 ? total + (part_numbers.first * part_numbers.last) : total
    end
  end

  # check the 8 spots around this spot looking for something
  def look_around_you(row, col)
    [row - 1, row, row + 1].each do |row_idx|
      [col - 1, col, col + 1].each do |col_idx|
        next if row_idx < 0 || col_idx < 0 || @schematic[row_idx].nil? || @schematic[row_idx][col_idx].nil? # skip if we would fall off the end of the array
        yield [@schematic[row_idx][col_idx], row_idx, col_idx]
      end
    end
  end

  def symbol_adjacent_coords?(row, col)
    # check the 8 spots around this spot looking for symbols
    # what is a symbol anyways? not a digit, not a period
    found_a_symbol = false
    look_around_you(row, col) { |px, _r, _c| found_a_symbol ||= (px =~ /[^\d\.]/) }
    return found_a_symbol
  end

  def adjacent_gear_coords(row, col)
    # check the 8 spots looking specifically for a '*'
    coords = []
    look_around_you(row, col) { |px, row_idx, col_idx| coords = [row_idx, col_idx] if px == '*' }

    coords unless coords.empty?
  end
end

puts "Test Output"
schema = SchematicParser.new(test)
test_out = schema.part_numbers.sum
puts "Passing? #{test_out} == 4361? #{test_out == 4361}"

puts "Part 1 Output"
p SchematicParser.new(input).part_numbers.sum

puts "Test Output"
puts "Gears: #{schema.gears.inspect}"
test_out = schema.combined_gear_ratio
puts "Passing? #{test_out} == 467835 #{test_out == 467835}"

puts "Part 2 Output"
p SchematicParser.new(input).combined_gear_ratio