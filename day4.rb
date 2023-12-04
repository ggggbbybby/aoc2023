input = File.read("input4.txt")
test = <<TXT
Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
TXT

class ScratchoffCalculator
  def initialize(cards_list)
    @cards = cards_list.split("\n").map { |card| Card.parse(card) }
  end

  class Card
    def self.parse(card_string)
      chunks = card_string.scan(/[\d\|]+/)
      card_num = chunks.first
      pipe_idx = chunks.index('|')
      winning_numbers = chunks[1 ... pipe_idx]
      my_numbers = chunks[pipe_idx + 1 .. -1]

      new(num: card_num, winning_numbers: winning_numbers, my_numbers: my_numbers)
    end

    def initialize(num:, winning_numbers:, my_numbers:)
      @num = num.to_i
      @winning_numbers = Set.new(winning_numbers.map(&:to_i))
      @my_numbers = Set.new(my_numbers.map(&:to_i))
    end

    def num
      @num
    end

    def matches
      @matches ||= @winning_numbers.intersection(@my_numbers)
    end

    # Part 1 score calculation
    def score
      # puts "Calculating Score: #{matches.length} matches in #{@winning_numbers} && #{@my_numbers}"
      count = matches.length
      return 0 if count == 0
      2 ** (count - 1)
    end

    # this method is from an earlier, much much slower and more memory intensive approach
    # it isn't used for anything. I just kept it because it's funny.
    def spawns(pool)
      matching_count = matches.length
      return [] if matching_count == 0
     
      idx = pool.index { |card| card.num == num }
      # puts "Card #{idx} has #{matching_count} matches -> spawning cards[#{idx+1} thru #{idx+matching_count}]"
      # copy the next N cards
      pool[idx+1 .. idx+matching_count].map(&:dup)
    end
  end

  def winnings
    @cards.map(&:score).sum
  end

  # Part 2 "score" calculation
  def card_count
    card_range = (0 ... @cards.length)
    card_idxs_to_process = card_range.map { |idx| [idx, 1] }.to_h
    #processed_cards = card_range.map { |idx| [idx, 0] }.to_h
    spawn_table = card_range.map do |idx|
      card = @cards[idx]
      match_count = card.matches.length
      spawns = match_count > 0 ? (idx + 1 .. idx + match_count).to_a : []
      [
        idx,
        spawns
      ]
    end.to_h

    counter = 0
    while card_idxs_to_process.values.any?(&:positive?) do
      card_range.each do |card_idx|
        next if card_idxs_to_process[card_idx] == 0

        #print "processing card[#{card_idx}]: "
        # decrement this card's counter in the 'todo' list and increment it in the 'done' list
        card_idxs_to_process[card_idx] -= 1
        #processed_cards[card_idx] += 1

        #puts "spawns: #{spawn_table[card_idx].count}"
        # increment each spawn counter
        spawn_table[card_idx].each { |spawn_id| card_idxs_to_process[spawn_id] += 1 }
        
        counter += 1
        #puts "Inbox: #{card_idxs_to_process.values.sum}, Outbox: #{counter}" if counter % 10000 == 0
      end
      end
    counter
  end
end

puts "Test Output"
calc_test = ScratchoffCalculator.new(test)
p calc_test.winnings

puts "Part 1"
calc_input = ScratchoffCalculator.new(input)
p calc_input.winnings

puts "Part 2"
p calc_test.card_count

start_t = Time.now
p calc_input.card_count # this takes 30MB of memory & about 45 seconds, you have been warned
puts "#{Time.now - start_t} seconds elapsed"