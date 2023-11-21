require 'matrix'

class Digit
  attr_accessor :label, :image

  def initialize(label, image)
    @label = label
    @image = image
  end

  def ones_in_image
    @image.to_a.flatten.count(1)
  end

  def to_s
    str = "Label: #{@label}"
    @image.each_with_index do |val, idx|
      str << "\n" if (idx % 28).zero?
      str << (val.zero? ? '. ' : '@ ')
    end
    str
  end
end
