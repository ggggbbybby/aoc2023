square_loop = <<TXT
.....
.S-7.
.|.|.
.L-J.
.....
TXT

dirty_square_loop = <<TXT
-L|F7
7S-7|
L|7||
-L-J|
L|-JF
TXT

complex_loop = <<TXT
7-F7-
.FJ|7
SJLL7
|F--J
LJ.LJ
TXT

loop_with_insides = <<TXT
...........
.S-------7.
.|F-----7|.
.||.....||.
.||.....||.
.|L-7.F-J|.
.|..|.|..|.
.L--J.L--J.
...........
TXT

larger_loop = <<TXT
.F----7F7F7F7F-7....
.|F--7||||||||FJ....
.||.FJ||||||||L7....
FJL7L7LJLJ||LJ.L-7..
L--J.L7...LJS7F-7L7.
....F-J..F7FJ|L7L7L7
....L7.F7||L7|.L7L7|
.....|FJLJ|FJ|F7|.LJ
....FJL-7.||.||||...
....L---J.LJ.LJLJ...
TXT

challenge = File.read("input10.txt")

class PipeMapper
  NORTH_PIPES = %w(└ ┘ | S) # S is a wildcard that could be any kind of corner
  SOUTH_PIPES = %w(┌ ┐ | S)
  EAST_PIPES = %w(┌ └ - S)
  WEST_PIPES = %w(┐ ┘ - S)

  def initialize(diagram)
    @pipes = diagram.split("\n").map { |row| replace_misleading_pipes(row.split("")) }
    @start = s_coords
    @max_row = @pipes.length - 1
    @max_col = @pipes[@max_row].length - 1
    @visited = Hash.new { |h, k| h[k] = {} }
  end

  def replace_misleading_pipes(row)
    # replace all of these janky ascii art characters with less confusing ones
    row.map { |p| p.gsub('L', '└').gsub('F', '┌').gsub('7', '┐').gsub('J', '┘') }
  end

  def replace_unvisited_pipes
    # don't call this one unless you've already counted distances, it'll blank out your map
    (0..@max_row).each do |row_idx|
      (0..@max_col).each do |col_idx|
        next if @visited.dig(row_idx, col_idx)
        @pipes[row_idx][col_idx] = "."
      end
    end
  end

  def pipes_out
    # this pretty prints your map
    puts @pipes.map(&:join)
  end

  def s_coords
    row = @pipes.index { |row| row.include?('S') }
    col = @pipes[row].index('S')
    [row, col]
  end

  def orient(s, a, b)
    srow, scol = s # this is our starting point

    dirs = [a, b].map do |row, col|
      if row == srow
        if col == scol - 1
          :west
        else
          :east
        end
      elsif row == srow - 1
         :north
      else
        :south
      end
    end

    case dirs.sort
    when [:east, :north]
      '└'
    when [:north, :west]
      '┘'
    when [:east, :south]
      '┌'
    when [:south, :west]
      '┐'
    else
      raise "panic! #{dirs}"
    end
  end

  def distances_from_s
    current_distance = 0
    row, col = @start
    
    branch_A, branch_B = adjacent_pipes('S', row, col)

    # start is some kind of corner, but which kind?
    @pipes[row][col] = orient(@start, branch_A, branch_B)
    @visited[row][col] = current_distance
    # puts "Replaced S with #{@pipes[row][col]}"

    while !branch_A.empty? || !branch_B.empty?
      pipeA = @pipes.dig(*branch_A)
      pipeB = @pipes.dig(*branch_B)

      current_distance += 1
      @visited[branch_A.first][branch_A.last] = current_distance
      @visited[branch_B.first][branch_B.last] = current_distance

      # binding.irb
      branch_A = adjacent_pipes(pipeA, *branch_A).flatten
      branch_B = adjacent_pipes(pipeB, *branch_B).flatten
      # pipes_out
    end
    current_distance
  end 

  def adjacent_pipes(pipe, row, col)
    # these are the coordinates of adjacent spots if it's within bounds and 
    north = [row - 1, col] if row > 0 
    south = [row + 1, col] if row < @max_row 
    east = [row, col + 1] if col < @max_col 
    west = [row, col - 1] if col > 0 

    matches = []

    # these matching conditions are confusing - here's the readable version:
    # if there is a valid pixel to the north
    #   and we haven't visited it yet
    #   and the current pipe points north 
    #   and the pipe at the north coordinates points south, 
    # then they can connect

    # binding.irb

    if north && @visited.dig(*north).nil? && NORTH_PIPES.include?(pipe) && SOUTH_PIPES.include?(@pipes.dig(*north))
      # puts "you can go north from #{row}, #{col}"
      matches << [row - 1, col]
    end

    if south && @visited.dig(*south).nil? && SOUTH_PIPES.include?(pipe) && NORTH_PIPES.include?(@pipes.dig(*south)) 
      # puts "you can go south from #{row}, #{col}"
      matches << [row + 1, col]
    end

    if east && @visited.dig(*east).nil? && EAST_PIPES.include?(pipe) && WEST_PIPES.include?(@pipes.dig(*east)) 
      # puts "you can go east from #{row}, #{col}"
      matches << [row, col + 1]
    end

    if west && @visited.dig(*west).nil? && WEST_PIPES.include?(pipe) && EAST_PIPES.include?(@pipes.dig(*west)) 
      # puts "you can go west from #{row}, #{col}"
      matches << [row, col - 1]
    end

    matches
  end

  def highlight_insides(char='*')
    (0..@max_row).each do |row_idx|
      (0..@max_col).each do |col_idx|
        next unless @visited.dig(row_idx, col_idx).nil?

        # this is a cool math trick! if you are on the inside of a polygon, you will cross an odd number of walls to reach the outside
        # but if you aren't on the inside, you'll cross an even number of walls
        # that's the "even-odd rule", pretty neat
        # (thanks to reddit user u/tomi901 <3)
        
        left = @pipes[row_idx][0...col_idx]
        right = @pipes[row_idx][col_idx + 1 .. @max_col]

        if count_walls(left).odd? && count_walls(right).odd?
          # puts "overwriting #{pipe} at (#{row_idx}, #{col_idx}) with *"
          @pipes[row_idx][col_idx] = "*"
        end
      end
    end
  end

  def count_walls(ray)
    # a wall is ???
    # it's not just continuous wall characters, because || is 2 walls and so is └---┘ but ┌--┘ is 1 wall
    # since we're looking left and right, let's define a wall as a "line that goes north" because if you see two of those, you can't be inside them
    ray.count { |c| NORTH_PIPES.include?(c) }
  end

  def inside_count
    @pipes.flatten.count { |p| p == '*' }
  end
end

inputs = {
  square_loop: square_loop,
  dirty_square_loop: dirty_square_loop,
  complex_loop: complex_loop,
  loop_with_insides: loop_with_insides,
  larger_loop: larger_loop,
  challenge: challenge
}

inputs.each do |name, diagram|
  start_time = Time.now
  puts "input: #{name}"
  mapper = PipeMapper.new(diagram)
  puts "distances_from_s: #{mapper.distances_from_s} in #{Time.now - start_time} seconds"
  start_time = Time.now
  mapper.replace_unvisited_pipes
  mapper.highlight_insides
  puts "inside_count: #{mapper.inside_count} in #{Time.now - start_time} seconds"
  if name == :challenge
    # save the output because it's pretty
    File.open('map10.txt', 'w') { |f| f.puts mapper.instance_variable_get(:@pipes).map(&:join) }
  end
end
