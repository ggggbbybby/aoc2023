input = File.read("input5.txt")
test = <<TXT
seeds: 79 14 55 13

seed-to-soil map:
50 98 2
52 50 48

soil-to-fertilizer map:
0 15 37
37 52 2
39 0 15

fertilizer-to-water map:
49 53 8
0 11 42
42 0 7
57 7 4

water-to-light map:
88 18 7
18 25 70

light-to-temperature map:
45 77 23
81 45 19
68 64 13

temperature-to-humidity map:
0 69 1
1 0 69

humidity-to-location map:
60 56 37
56 93 4
TXT

class MapsGame
  def initialize(maps_text)
    @maps = parse_maps(maps_text)
  end

  class Filter
    def initialize(dest_start, source_start, length)
      @source_start = source_start
      @dest_start = dest_start
      @length = length
    end
  
    def f_start
      @source_start
    end
  
    def f_end
      @source_start + @length
    end
  
    def f_offset
      @dest_start - @source_start
    end
  
    def to_s
      "filter from (#{@source_start ... @source_start + @length}) -> (#{(@dest_start ... @dest_start + @length)})"
    end
  
    def applies?(range_start, range_length)
      !((range_start + range_length) <= f_start) && !(f_end <= range_start)
    end
  
    # r_start does not have to be the literal range start
    # it's more of an index
    def chunks(r_start, r_end)
      return [] unless applies?(r_start, r_end - r_start)
  
      # pre-chunk includes the source range chunk before the filter starts
      pre_chunk = [r_start, f_start - r_start, 0] if r_start < f_start
      
      match_start = [r_start, f_start].max
      match_end = [f_end, r_end].min
      match_chunk = [match_start, match_end - match_start, f_offset]
  
      # there is no post-chunk because we don't know where the next filter starts, it might start immediately after this one
      # we aren't doing anything with those ids in this filter anyways. that's the job of the compositor.
      # p [pre_chunk, match_chunk]
      return [pre_chunk, match_chunk].compact
    end
  end
  
  class FilterCompositor
    def initialize(filters)
      @filters = filters.sort_by(&:f_start)
    end
  
    def chunks(r_start, r_length)
      applicable = @filters.select { |f| f.applies?(r_start, r_length) }
      return [[r_start, r_length, 0]] if applicable.empty?
      
      # otherwise we need to break up the source range into chunks where exactly one filter applies
      chunks_out = []
      last_match = applicable.inject(r_start) do |idx, filter|
        #puts "starting at #{idx}, applying #{filter}"
        # we know that the filters are sorted so we can work left to right
        chunks_out += filter.chunks(idx, r_start + r_length) # these are still in source coords
        # our new iteration starts at the spot where these chunks end
        chunks_out.last[0..1].sum
      end
      # if we didn't reach the end of the range, we have a right-hand chunk to deal with
      if last_match < r_start + r_length
        r_end = r_start + r_length
        chunks_out << [last_match, r_end - last_match, 0]
      end
      chunks_out
    end
  
    def chunk_and_transform_ranges(ranges)
      # for each range, divide it into chunks and apply the offset to get new ranges
      ranges.inject([]) do |chunks_out, range|
        range_chunks = chunks(*range)
        #puts "#{range.inspect} -> #{range_chunks.inspect}"
        chunks_out + range_chunks.map { |r_start, r_length, r_offset| [r_start + r_offset, r_length] }
      end.sort
    end
  end
  
  def parse_maps(maps_text)
    chunks = maps_text.split("\n\n").map { |c| c.split("\n") }
    chunks.each_with_object({}) do |(head, *tail), memo|
      case head
      when /seeds: /
        memo[:seeds] = read_numbers(head)
      when /(\w+)-to-(\w+) map:/
        from_id, to_id = [$1, $2]
        memo[from_id] = 
        {
          to: to_id,
          ranges: tail.map { |t| read_numbers(t) }
        }
      end
    end
  end

  def read_numbers(line)
    line.scan(/\d+/).map(&:to_i)
  end

  def map_list
    @map_list ||= @maps.except(:seeds)
  end
  
  def seeds
    @seeds ||= @maps[:seeds]
  end

  def best_location_for_individual_seeds
    # I like my part2 solution better so we're going to use it here too
    seed_ranges = seeds.flat_map { |seed_id| [seed_id, 1] }
    best_location_for_seed_ranges(seed_ranges)
  end

  def best_location_for_seed_ranges(seed_inputs)
    init_ranges = seed_inputs.each_slice(2).to_a
    map_list.inject(init_ranges) do |ranges, (unit, conversion_factors)|
      puts "#{unit} conversion to #{conversion_factors[:to]}"
      filters = conversion_factors[:ranges].map { |range| Filter.new(*range) }
      FilterCompositor.new(filters).chunk_and_transform_ranges(ranges)
    end.first
  end
end

puts "Part 1"
test_game = MapsGame.new(test)
real_game = MapsGame.new(input)

print "Test Output: "
p test_game.best_location_for_individual_seeds

print "Real Output: "
p real_game.best_location_for_individual_seeds

puts "Part 2"

print "Test Output: "
p test_game.best_location_for_seed_ranges(test_game.seeds)

print "Real Output: "
p real_game.best_location_for_seed_ranges(real_game.seeds)