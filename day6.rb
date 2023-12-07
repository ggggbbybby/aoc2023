input = File.read("input6.txt")
test = <<TXT
Time:      7  15   30
Distance:  9  40  200
TXT

class TofuDeliveryMan # I think if we're being technical, this is more like those rich brother from season 1 than the tofu delivery teen

  def initialize(records)
    @times, @distances = records.split("\n")
  end

  def records
    read_numbers(@times).zip(read_numbers(@distances))
  end

  def one_big_race
    time = @times.gsub(/[^\d]+/, '').to_i
    distance = @distances.gsub(/[^\d]+/, '').to_i
    puts "one big race: #{distance} mm in #{time} seconds"
    [[time, distance]]
  end

  def read_numbers(string)
    string.scan(/\d+/).map(&:to_i)
  end

  def winning_button_timings(race_time, record_distance)
    # what's the fastest time where we finish above the record_distance?
    # distance_traveled = (total_time - button_time) * (1 mm/second)(button_time)
    # we need actual_distance > record_distance and we want to find all of the integer button times where that happens
    # record_distance < (race_time - button_time) * button_time # does this work? you can win a (7, 9) race with button_time = 2 -> 9 < (7 - 2) * 2 is true, 9 < 10
    # record_distance + button_time^2 - (button_time * race_time) < 0 # does this work? 9 + 2*2 - (2 * 7) < 0 is true (13 - 14 = -1)
    #puts "Calculating for race with time: #{race_time}, distance: #{record_distance}"
    #puts "solve for x: x**2 - #{race_time}*x + #{record_distance} < 0"

    b = race_time * - 1
    c = record_distance + 1 # we want to actually pass the old record, not just meet it
    x1 = ((-b - Math.sqrt(b**2 - 4*c)) / 2).ceil
    x2 = ((-b + Math.sqrt(b**2 - 4*c)) / 2).floor
    # p [x1, x2]
    (x1 .. x2)
  end

  def margin_of_error(races)
    options_per_race = races.map { |race| winning_button_timings(*race).size }
    options_per_race.inject(&:*)
  end
end

puts "Part 1"

print "Test Output: "
test_driver = TofuDeliveryMan.new(test)
p test_driver.margin_of_error(test_driver.records)

print "Real Output: "
real_driver = TofuDeliveryMan.new(input)
p real_driver.margin_of_error(real_driver.records)


puts "Part 2"
print "Test Output: "
p test_driver.margin_of_error(test_driver.one_big_race)

print "Real Output: "
p real_driver.margin_of_error(real_driver.one_big_race)