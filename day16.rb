class PinballWizard
  def initialize(board)
    @board = board.split("\n").map { |r| r.split("") }
  end

  def part1
    beam_path(0, 0, :east).length
  end

  def part2
    max_row = @board.length - 1
    max_col = @board.first.length - 1
    
    puts "top row going south:"
    top_down = (0..max_col).map { |col_idx| beam_path(0, col_idx, :south).length }

    puts "bottom row going north:"
    bottom_up = (0..max_col).map { |col_idx| beam_path(max_row, col_idx, :north).length }

    puts "left row going east:"
    left_to_right = (0..max_row).map { |row_idx| beam_path(row_idx, 0, :east).length }

    puts "right row going west:"
    right_to_left = (0..max_row).map { |row_idx| beam_path(row_idx, max_col, :west).length }

    [top_down.max, bottom_up.max, left_to_right.max, right_to_left.max].max
  end

  MIRRORS = {
    "/" => {
      north: :east,
      south: :west,
      east: :north,
      west: :south
    },
    "\\" => {
      north: :west,
      west: :north,
      south: :east,
      east: :south
    }
  }

  def beam_path(start_row, start_col, start_dir)
    to_visit = [[start_row, start_col, start_dir]]
    visited = Hash.new { |h,k| h[k] = {} }

    max_row = @board.length - 1
    max_col = @board.first.length - 1

    while !to_visit.empty?
      row, col, dir = to_visit.shift

      # if the coordinates are out of bounds, ignore them
      next if col < 0 || col > max_col || row < 0 || row > max_row 

      # if we've been here already headed in this direction, don't keep going around in a loop
      next if visited[row][col]&.include?(dir)

      visited[row][col] ||= Set.new
      visited[row][col] << dir

      if @board[row][col] == "\\" || @board[row][col] == "/"
        next_dir = MIRRORS[@board[row][col]][dir]
        next_row, next_col = next_coords(row, col, next_dir)
        to_visit << [next_row, next_col, next_dir]
      
      elsif @board[row][col] == "|" && (dir == :east || dir == :west)
        north_row, north_col = next_coords(row, col, :north)
        to_visit << [north_row, north_col, :north]
        south_row, south_col = next_coords(row, col, :south)
        to_visit << [south_row, south_col, :south]

      elsif @board[row][col] == "-" && (dir == :north || dir == :south)
        east_row, east_col = next_coords(row, col, :east)
        to_visit << [east_row, east_col, :east]
        west_row, west_col = next_coords(row, col, :west)
        to_visit << [west_row, west_col, :west]
      else
        # this no mirrors, no splitters, just passing through
        next_row, next_col = next_coords(row, col, dir)
        to_visit << [next_row, next_col, dir]
      end
    end

    visited.flat_map { |row_idx, cols| cols.map { |col_idx, _| [row_idx, col_idx] } }
  end

  def next_coords(row, col, dir)
    case dir
    when :east
      [row, col + 1]
    when :west
      [row, col - 1]
    when :north
      [row - 1, col]
    when :south
      [row + 1, col]
    else
      raise "panic! unknown direction #{dir}"
    end
  end

end

test_input = <<'TXT' # TIL the quotes are how you tell it not to escape the backslashes. that was a fun bug to find.
.|...\....
|.-.\.....
.....|-...
........|.
..........
.........\
..../.\\..
.-.-/..|..
.|....-|.\
..//.|....
TXT

challenge_input = File.read("input16.txt")

puts "Test Output"
p PinballWizard.new(test_input).part1

puts "Part 1"
p PinballWizard.new(challenge_input).part1

puts "Part 2"
p PinballWizard.new(test_input).part2

p PinballWizard.new(challenge_input).part2