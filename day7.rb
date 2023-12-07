input = File.read("input7.txt")
test = <<TXT
32T3K 765
T55J5 684
KK677 28
KTJJT 220
QQQJA 483
TXT

class CamelPoker

  PARSING_RULES = {
    five_of_a_kind: ->(tally) { tally.values.uniq == [5] },
    four_of_a_kind: ->(tally) { tally.values.sort == [1, 4] },
    full_house: ->(tally) { tally.values.sort == [2, 3] },
    three_of_a_kind: ->(tally) { tally.values.sort == [1, 1, 3] },
    two_pair: ->(tally) { tally.values.sort == [1, 2, 2] },
    one_pair: ->(tally) { tally.values.sort == [1, 1, 1, 2] },
    high_card: ->(tally) { tally.values.uniq.length == 1 }
  }

  class Hand
    def self.parse(handstring, bidstring)
      card_strings = handstring.split("")
      # print "#{handstring}, "
      card_tally = card_strings.tally
      #hand_type = standard_hand_type(card_tally)
      hand_type = wildcard_hand_type(card_tally)
      # puts hand_type.first

      new(
        hand_type: hand_type,
        cards: card_strings.map { |cs| card(cs) },
        bid: bidstring.to_i
      )
    end

    HAND_HIERARCHY = PARSING_RULES.keys
    #CARD_HIERARCHY = %w(A K Q J T 9 8 7 6 5 4 3 2)
    CARD_HIERARCHY = %w(A K Q T 9 8 7 6 5 4 3 2 J)
    
    def self.card(card_string)
      { char: card_string, rank: CARD_HIERARCHY.index(card_string) }
    end

    def self.standard_hand_type(tally)
      PARSING_RULES.detect { |rule_name, rule_proc| rule_proc.call(tally) }.first
    end

    def self.wildcard_hand_type(tally)
      ignore_wildcards = standard_hand_type(tally)
      return ignore_wildcards if tally['J'].nil?

      # so we have at least one Joker
      upgrade_jokers(ignore_wildcards, tally['J'])
    end

    JOKER_UPGRADE_TABLE = {
      1 => {
        # if you've got one joker and you are a four_of_a_kind, now you are a five_of_a_kind
        four_of_a_kind: :five_of_a_kind, #AAAAJ
        # and so on
        three_of_a_kind: :four_of_a_kind, #AAABJ
        two_pair: :full_house, #AABBJ
        one_pair: :three_of_a_kind, #AABCJ
        high_card: :one_pair # ABCDJ
      },
      2 => {
        full_house: :five_of_a_kind, # AAAJJ
        # three_of_a_kind isn't possible (it would have to be JJ+3-of-a-kind and that's a full house)
        two_pair: :four_of_a_kind, #AAJJB
        one_pair: :three_of_a_kind, #a gotcha! JJABC is not a full house
      },
      3 => {
        full_house: :five_of_a_kind, #JJJAA
        three_of_a_kind: :four_of_a_kind #JJJAB
      },
      4 => { four_of_a_kind: :five_of_a_kind },
      5 => { five_of_a_kind: :five_of_a_kind }
    }

    def self.upgrade_jokers(standard_type, jokers)
      JOKER_UPGRADE_TABLE[jokers][standard_type].tap { |upgrade| raise "ohno" if upgrade.nil? }
    end

    def initialize(hand_type:, cards:, bid:)
      @cards = cards
      @hand_type = hand_type
      @bid = bid
    end

    def bid
      @bid
    end

    def rank
      [HAND_HIERARCHY.index(@hand_type), *@cards.map {|c| c[:rank] }]
    end

    def to_s
      "#{@hand_type}: #{@cards.map {|c| c[:char] }.join("")} $#{@bid}"
    end

    def hand_type
      @hand_type
    end
  end

  def initialize(hands_and_bids)
    @hands = hands_and_bids.split("\s").each_slice(2).map { |handstring, bidstring| Hand.parse(handstring, bidstring) }
    
    #@hands.each { |h| puts "#{h} w/ rank #{h.rank}" }
  end

  def hands_by_type
    @hands.group_by(&:hand_type)
  end

  def hand_rankings
    @hands.sort_by(&:rank).reverse # rank 1 is the lowest for some reason
  end

  def total_winnings
    hand_rankings.inject(0) do |total, hand|
      # print hand
      hand_rank = hand_rankings.index(hand) + 1
      # puts ", rank ##{hand_rank}\t +#{hand_rank * hand.bid}"
      total + (hand_rank * hand.bid)
    end
  end
end

test_poker = CamelPoker.new(test)
p test_poker.total_winnings

real_poker = CamelPoker.new(input)
p real_poker.total_winnings