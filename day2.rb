input = File.read("input2.txt")

test = <<TXT
Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
TXT

class GamePossibilityJudge
  def self.possible_game_ids(bag, games)
    judge = new(bag)
    parse_games(games).select { |game| judge.possible?(game) }.map { |game| game[:id].to_i }
  end

  def self.minimum_possible_cubes(games)
    # use a bag to accumulate the minimum possible number of cubes of each color for each game
    min_cubes_per_game = parse_games(games).map do |game|
      game[:moves].each_with_object({}) do |move, bag| # { "blue" => 3, "red" => 4}
        move.each do |color, count|
          if bag[color].nil?
            bag[color] = count
          elsif bag[color] < count
            bag[color] = count
          end
        end
      end
    end
  end

  def self.parse_games(game_text)
    game_text.split("\n").map do |game_line|
      game_name, *game_moves = game_line.split(/[:;]/)
      id = game_name.scan(/\d+/).first.to_i
      moves = game_moves.map do |move| # " 3 blue, 4 red"
        pieces = move.strip.split(", ") # ["3 blue", "4 red"]
        pieces.map { |p| p.split(" ") }.each_with_object({}) { |(count, color), memo| memo[color] = count.to_i }
      end

      { id: id, moves: moves}
    end
  end

  def initialize(bag)
    @bag = bag
  end

  def possible?(game)
    #p game
    game[:moves].all? do |move| # { "blue" => 3, "red" => 4 }
      move.all? { |color, count| @bag[color] >= count }
    end
  end
end

bag = {
  "red" => 12,
  "green" => 13,
  "blue" => 14
}
puts "Part 1"
puts "Test Output:"
p GamePossibilityJudge.possible_game_ids(bag, test).sum

puts "Input:"
p GamePossibilityJudge.possible_game_ids(bag, input).sum

puts "Part 2"
puts "Test Output:"
mpc = GamePossibilityJudge.minimum_possible_cubes(test)
p mpc.map { |cubelist| cubelist.values.inject(&:*) }.sum

mpc = GamePossibilityJudge.minimum_possible_cubes(input)
p mpc.map { |cubelist| cubelist.values.inject(&:*) }.sum
