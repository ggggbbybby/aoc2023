input = File.read("input8.txt")
test1 = <<TXT
RL

AAA = (BBB, CCC)
BBB = (DDD, EEE)
CCC = (ZZZ, GGG)
DDD = (DDD, DDD)
EEE = (EEE, EEE)
GGG = (GGG, GGG)
ZZZ = (ZZZ, ZZZ)
TXT

test2 = <<TXT
LLR

AAA = (BBB, BBB)
BBB = (AAA, ZZZ)
ZZZ = (ZZZ, ZZZ)
TXT

testghost = <<TXT
LR

11A = (11B, XXX)
11B = (XXX, 11Z)
11Z = (11B, XXX)
22A = (22B, XXX)
22B = (22C, 22C)
22C = (22Z, 22Z)
22Z = (22B, 22B)
XXX = (XXX, XXX)
TXT

class Wanderer
  def initialize(instructions)
    moves, _, *network = instructions.split("\n")
    @moves = moves.chars
    @network = parse_network(network)
    # p @moves
    # p @network
  end

  def parse_network(network)
    network.each_with_object({}) do |line, memo|
      start, left, right = line.scan(/\w+/)
      memo[start] = { "L" => left, "R" => right }
    end
  end

  def steps_from_aaa_to_zzz
    steps('AAA') { |loc| loc == 'ZZZ' }
  end
  
  def steps(starting_location)
    step_count = 0
    location = starting_location

    @moves.cycle do |left_or_right|
      step_count += 1
      location = @network[location][left_or_right]
      # puts "On Step #{step_count} at #{location}"
      break if yield location, step_count
    end

    step_count
  end

  def ghost_steps
    starts = @network.keys.select { |k| k.end_with?('A') }
    ends = @network.keys.select { |k| k.end_with?('Z') }

    # there's a pretty big assumption baked into the next step and that's that every end is reachable by exactly one start
    # and that they are in the same order in the input data. that holds up for this input, but isn't guaranteed for every possible input.

    loops = starts.zip(ends).map { |nodeA, nodeZ| loop_length(nodeA, nodeZ) }
    loops.inject { |memo, ll| memo.lcm(ll) }
  end

  def loop_length(start_node, end_node)
    # this is another wild assumption that really only holds up for this input data: every loop for a set of start&end is the same length
    # so this method and the regular steps method return the same number, which is wild

    cycles = []
    steps(start_node) { |n, step_count| cycles << step_count if n.end_with?('Z') ; break if cycles.length > 3 }
    cycles.each_cons(2).with_object([]) { |(s1, s2), acc| acc << (s2 - s1) }.uniq.first
  end
end

puts "Part 1"
puts "Test Output"
p Wanderer.new(test1).steps_from_aaa_to_zzz

p Wanderer.new(test2).steps_from_aaa_to_zzz

puts "Challenge Output"
p Wanderer.new(input).steps_from_aaa_to_zzz

puts "Part 2"
p Wanderer.new(testghost).ghost_steps

p Wanderer.new(input).ghost_steps
