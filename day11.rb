mini_galaxy = <<TXT
...#......
.......#..
#.........
..........
......#...
.#........
.........#
..........
.......#..
#...#.....
TXT

galaxy = File.read("input11.txt")

class GalaxyDistancer
  def initialize(galaxies)
    @universe = galaxies.split("\n").map { |row| row.split("") }
    # behold

    # expand_the_universe
    # name_the_galaxies
    # behold
  end

  def behold
    puts @universe.map(&:join)
    p @galaxies if @galaxies
    puts "="*40
  end

  def name_the_galaxies
    galaxy_count = 0
    @galaxies ||= {}.tap do |memo|
      @universe.each_with_index do |row, row_idx|
        row.each_with_index do |col, col_idx|
          if col == '#'
            galaxy_count += 1
            memo[galaxy_count] = [row_idx, col_idx]
          end
        end
      end
    end
  end

  def expand_the_universe
    # this manually expands the universe, but since we have `expansion_rate=` now it isn't very useful
    row_length = @universe.first.length
    row_idxs = @universe.each_with_object([]).with_index do |(row, rows), idx|
      rows << idx if row.all? { |c| c == "." }
    end
    # p row_idxs
    # if we insert from the largest to the smallest then we don't have to keep offsetting our indices
    row_idxs.reverse.each do |insert_idx|
      @universe.insert(insert_idx, ['.'] * row_length)
    end

    col_height = @universe.length
    col_idxs = (0...@universe.first.length).select do |idx| 
      @universe.all? { |row| row[idx] == "." }
    end
    # p col_idxs
    (0...col_height).each do |row_idx|
      col_idxs.reverse.each { |insert_idx| @universe[row_idx].insert(insert_idx, '.') }
    end
  end

  def expansion_rate=(rate)
    @expansion_rate = rate
  end

  def shortest_paths
    empty_row_idxs = (0...@universe.length).select do |idx|
      @universe[idx].all? { |c| c == "." }
    end

    empty_col_idxs = (0...@universe.first.length).select do |idx| 
      @universe.all? { |row| row[idx] == "." }
    end

    pairs = @galaxies.keys.combination(2).to_a
    pairs.inject(0) do |sum, (a, b)|
      ay, ax = @galaxies[a]
      by, bx = @galaxies[b]
      delta_x = (ax - bx).abs + ((@expansion_rate - 1) * empty_col_idxs.count { |col_idx| (col_idx > ax && col_idx < bx) || (col_idx > bx && col_idx < ax) })
      delta_y = (ay - by).abs + ((@expansion_rate - 1) * empty_row_idxs.count { |row_idx| (row_idx > ay && row_idx < by) || (row_idx > by && row_idx < ay) })
      # binding.irb
      sum + delta_x + delta_y
    end
  end
end

puts "Part 1"
puts "Test Out"
mini_map = GalaxyDistancer.new(mini_galaxy)
mini_map.expansion_rate = 2
# mini_map.expand_the_universe
mini_map.name_the_galaxies
p mini_map.shortest_paths

puts "Challenge Out"
galaxy_map = GalaxyDistancer.new(galaxy)
# galaxy_map.expand_the_universe
galaxy_map.expansion_rate = 2
galaxy_map.name_the_galaxies
p galaxy_map.shortest_paths

puts "Part 2"
puts "Test Out"

minimap = GalaxyDistancer.new(mini_galaxy)
minimap.name_the_galaxies

puts "factor = 1"
minimap.expansion_rate = 2
p minimap.shortest_paths

puts "factor = 10"
minimap.expansion_rate = 10
p minimap.shortest_paths

puts "factor = 100"
minimap.expansion_rate = 100
p minimap.shortest_paths

puts "Challenge Out"
puts "factor = 1_000_000"
galaxy_map.expansion_rate = 1_000_000
p galaxy_map.shortest_paths