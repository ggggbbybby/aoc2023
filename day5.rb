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
    @converter = Converter.new(map_list)
  end

  class Converter
    def initialize(ranges)
      @ranges = ranges
    end

    def convert(value, unit)
      next_unit = @ranges[unit][:to]

      # shoutout to stack overflow for this next trick
      next_value = @ranges[unit][:ranges].lazy.map do |dst_start, src_start, length|
        # I want to find the first range where value is between (src_start ... src_start + length) 
        # then I want to return dst_start + that offset
        (value >= src_start && value < src_start + length) && (dst_start + (value - src_start)) 
      end.find(&:itself) || value # in case next_value is nil
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

  def almanac
    seeds.map { |seed_id| convert_to_location(seed_id, 'seed') }
  end

  def map_list
    @map_list ||= @maps.except(:seeds)
  end
  
  def seeds
    @seeds ||= @maps[:seeds]
  end

  def each_seed(&block)
    # don't want to instantiate a huge ass list for no real benefit? i got u bro
    seeds.each_slice(2).each do |start, length|
      puts "Evaluating Range #{start} - #{start + length}"
      (start ... start+length).each { |seed_id| yield seed_id }
    end
  end

  def convert_one_seed
    seed_id = seeds.first
    convert_to_location(seed_id, 'seed')
  end

  def convert_to_location(init_value, init_unit)
    value = init_value
    unit = init_unit
    while unit != 'location' # I do love a good while loop # this used to be recursive but it would run out of memory # lol it still runs out of memory
      next_value = @converter.convert(value, unit)
      # iterate again
      unit = map_list[unit][:to]
      value = next_value
    end
    return value
  end

  # that didn't work, what if we worked backwards? find the first location that matches a seed
  def each_location(&block)
    (1..).each do |location|
      break if yield(location)
    end
  end

  def convert_one_location(n=1)
    [n, convert_to_seed(n, 'location')]
  end

  # run the conversions in reverse
  def convert_to_seed(init_value, init_unit)
    value = init_value
    unit = init_unit
    
    while unit != 'seed' || unit.nil?
      next_unit, conversion_map = map_list.detect { |k, v| v[:to] == unit }
      
      next_value = nil
      conversion_map[:ranges].each { |src_start, dst_start, length| next_value ||= (value >= dst_start && value < dst_start + length) && (src_start + (value - dst_start)) ; break if next_value }
      
      value = next_value || value
      unit = next_unit
    end

    return value
  end
end

puts "Part 1"
p MapsGame.new(test).almanac.min

p MapsGame.new(input).almanac.min

puts "Part 2"
# ok so I tried a lot of things and then I looked at other people's solutions 
# and the trick (one trick at least) is to just transform the whole range instead of iterating over the individual elements
# so lets try that



class Filter
  def initialize(source_start, dest_start, length)
    @source_start = source_start
    @dest_start = dest_start
    @length = length
  end

  def to_s
    "filter from (#{@source_start ... @source_start + @length}) -> (#{(@dest_start ... @dest_start + @length)})"
  end

  def transform(range_start, range_length)
    # take a source range like [79, 79+14]
    # and convert it to a destination range like [???, ???] or possibly [[???, ???], [???, ???], ...]
    ranges = []
    puts "applying #{to_s} on #{(range_start ... range_start + range_length)}"
    if (range_start + range_length < @source_start) || (@source_start + @length < range_start)
      # all of this range is outside the target filter
      puts "case 1: no overlap #{(range_start ... range_start + range_length)} -> #{(range_start ... range_start + range_length)}"
      ranges = [range_start, range_length]
    elsif (range_start >= @source_start && range_start + range_length <= @source_start + @length)
      # all of this range is inside the target filter
      new_start = range_start + (@dest_start - @source_start)
      puts "case 2: range is inside filter #{(range_start ... range_start + range_length)} -> #{(new_start ... new_start + length)}"
      ranges = [new_start, length]
    else # there's some kind of complicated overlap happening
      # left-chunk: don't map the ids between range_start and @source_start
      puts "case 3 starting range #{range_start ... range_start + range_length}"
      if range_start < @source_start
        puts "case 3 left-chunk: #{(range_start ... @source_start)}"
        ranges << [range_start, @source_start]
      end

      # handle the overlapping section (we know it exists)
      overlap_src_start =  [@source_start, range_start].max # transform source-start or 
      overlap_src_end = [@source_start + @length, range_start + range_length].min
      # map src values to dest values
      overlap_dest_start = @dest_start + (overlap_src_start - @source_start)
      overlap_length = overlap_src_end - overlap_src_start
      puts "case 3 center-chunk: #{(overlap_dest_start ... overlap_dest_start + overlap_length)}"
      ranges << [overlap_dest_start, overlap_length]

      # right-chunk: don't filter the ids between @source-end and range-end
      if (range_start + range_length > @source_start + @length)
        puts "case 3 right-chunk: #{@source_start + @length ... (range_start + range_length)} "
        ranges << [@source_start + @length, (range_start + range_length - @source_start - @length)]
      end
    end
    ranges
  end
end

class FilterCompositor
  # given a set of filters and a piecewise range
  # return a new piecewise range

  # ugh this sucks

end

tester = MapsGame.new(test)
# filters = tester.map_list.map { |ml| Filter.new(ml) }
#tester.seeds.each_slice(2).map do |(range_start, length)|
seed_ranges = [[79, 14], [55, 13]]
puts "Soil Map"
soil_map = tester.map_list['soil']
p soil_map

puts "Soil Filters"
soil_filters = soil_map[:ranges].map { |range| Filter.new(*range) }
p soil_filters
soil_ranges = seed_ranges.map { |seed_range| soil_filters.inject([]) { |memo, f| memo += f.transform(*seed_range) }.uniq }
p soil_ranges # I want this to look identical to seed_ranges bc no mapping has happened yet
puts "ok? #{soil_ranges == seed_ranges}"

puts "Fertilizer Map"
fertilizer_map = tester.map_list['fertilizer']
p fertilizer_map

puts "Fertilizer Filters"
fertilizer_filters = fertilizer_map[:ranges].map { |range| Filter.new(*range) }
puts fertilizer_filters


p fertilizer_filters.map { |f| f.transform(79, 14) }.uniq # should eq [[79, 14]]
p fertilizer_filters.map { |f| f.transform(55, 13) } # should eq [ [[59, 2], [57, 11]], [55, 13], [55, 13], [[55, 2], [7, 4], [61, 7]] ]
p fertilizer_filters.inject do |memo, f|
  filtered = f.transform(55, 13)
  if filtered == [55, 13] # no changes were made
    memo
  else

  end
end

# should reduce to [[55, 2], [7, 4], [61, 7]]

#fertilizer_ranges = soil_ranges.flat_map do |soil_range| 
#  fertilizer_filters.map { |f| f.transform(*soil_range) }.uniq
#end
#p fertilizer_ranges # this should look like [ [79, 14], [55, 2], [7, 4], [61, 7] ]