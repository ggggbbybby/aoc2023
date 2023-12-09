input = File.read("input9.txt")

test = <<TXT
0 3 6 9 12 15
1 3 6 10 15 21
10 13 16 21 30 45
TXT

class Oasis
  def initialize(sequences)
    @generations = list_generations(sequences) 
  end

  def generations
    @generations
  end

  def list_generations(text)
    sequences = text.split("\n").map { |line| line.split(" ").map(&:to_i) }

    sequences.map { |sequence| subseq_generation(sequence, []) }
  end

  def subseq_generation(initial, generations)
    # p initial
    generations << initial
    return generations if initial.all?(&:zero?)

    differences = initial.each_cons(2).map { |x, y| y - x }
    subseq_generation(differences, generations)
  end

  def next_values
    # lets make bad decisions about looping strategies

    (0...generations.count).each do |outer_idx|
      generation = generations[outer_idx]
      # p generation
      (generation.count-1).downto(1).each do |inner_idx|
        tos = generation[inner_idx]
        tng = generation[inner_idx - 1]

        tng << tos.last + tng.last

        # puts "#{tos.inspect} -> #{tng.inspect}"
      end
    end
  end

  def prev_values
    # wow ok lets do this

    (0...generations.count).each do |outer_idx|
      generation = generations[outer_idx]
      # p generation

      (generation.count-1).downto(1).each do |inner_idx|
        tos = generation[inner_idx]
        tng = generation[inner_idx - 1]

        tng.unshift(tng.first - tos.first)
      end
    end
  end
end

puts "Part 1"
oasis = Oasis.new(test)
oasis.next_values
p oasis.generations.map(&:first).map(&:last).reduce(&:+)

desertOasis = Oasis.new(input)
desertOasis.next_values
p desertOasis.generations.map(&:first).map(&:last).reduce(&:+)

puts "Part 2"
oasis.prev_values
p oasis.generations.map(&:first).map(&:first).reduce(&:+)

desertOasis.prev_values
p desertOasis.generations.map(&:first).map(&:first).reduce(&:+)