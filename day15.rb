test_steps = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7"

class Hashbrowns
  def initialize(steps)
    @steps = steps.strip.split(",")
  end

  def hashes
    @steps.map { |step| hash(step) }
  end

  def hash(step)
    step.chars.inject(0) do |hashsum, c|
      ((hashsum + c.ord) * 17) % 256
    end
  end

  def lens_powers
    lens_box = Hash.new {|h, k| h[k] = {} }
    @steps.each do |step|
      label, focal_length = step.split("=")
      if focal_length.nil?
        # this is a remove-lens step
        label = label[0...-1] # take the final `-` off
        label_hash = hash(label)
        lens_box[label_hash].delete(label)
      else
        label_hash = hash(label)
        lens_box[label_hash][label] = focal_length.to_i
      end

      #puts "After #{step}"
      #p lens_box
    end

    result = []
    lens_box.each do |box_num, lenses|
      lenses.each_with_index do |(label, focal_length), idx|
        result << (box_num + 1) * (idx + 1) * (focal_length)
      end
    end

    result.sum
  end
end

puts "Test Output"
p Hashbrowns.new("HASH").hashes
p Hashbrowns.new(test_steps).hashes

p Hashbrowns.new(test_steps).lens_powers

puts "Part 1"

challenge = File.read("input15.txt")
p Hashbrowns.new(challenge).hashes.sum

puts "Part 2"
p Hashbrowns.new(challenge).lens_powers