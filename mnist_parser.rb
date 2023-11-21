require 'zlib'
require_relative 'digit'
require 'matrix'

# https://github.com/gbuesing/mnist-ruby-test/blob/master/train/mnist_loader.rb
# https://web.archive.org/web/20230309190723/https://yann.lecun.com/exdb/mnist/
class MNISTParser
  SEED = 5

  def self.training_set
    new 'data/train-images-idx3-ubyte.gz', 'data/train-labels-idx1-ubyte.gz'
  end

  def self.test_set
    new 'data/t10k-images-idx3-ubyte.gz', 'data/t10k-labels-idx1-ubyte.gz'
  end

  def initialize(images_file, labels_file)
    @images_file = images_file
    @labels_file = labels_file

    return if File.exist?(@images_file) && File.exist?(@labels_file)

    raise "MNIST data not found.\nDownload from: http://yann.lecun.com/exdb/mnist/"
  end

  def get_data(size)
    load_data

    @digits[0...size]
  end

  def get_one_of_each_nbr
    load_data

    target_digits = Array.new(10)
    total = 0
    @digits.each do |digit|
      break if total == 10

      if target_digits[digit.label].nil?
        target_digits[digit.label] = digit
        total += 1
      end
    end
    target_digits.shuffle
  end

  def get_nbr(nbr, size)
    load_data

    target_digits = []
    @digits.each do |digit|
      break if target_digits.length == size

      target_digits << digit if digit.label == nbr
    end
    target_digits
  end

  # 5, 10, 10 would grab 10 labels of #5 and 10 labels of not #5.
  # Then it converts them to a format of [nbr, 'p'], [non-nbr, 'n']
  def get_exact_nbr(nbr, amount, non_amount)
    load_data

    target_digits = []
    nbr_count = 0
    non_count = 0
    @digits.each do |digit|
      break if nbr_count == amount && non_count == non_amount

      if digit.label == nbr && nbr_count < amount
        target_digits << digit
        nbr_count += 1
      elsif digit.label != nbr && non_count < non_amount
        target_digits << digit
        non_count += 1
      end
    end
    target_digits
  end

  private

  def load_data
    @images ||= image_data
    @labels ||= label_data
    @digits ||= initial_data_loading
    @digits.shuffle!(random: Random.new(SEED))
  end

  def initial_data_loading
    puts 'Initial data loading, please wait...'
    @images.map.with_index { |image, idx| Digit.new(@labels[idx], Matrix.column_vector(image)) }
  end

  def image_data
    images = []

    Zlib::GzipReader.open(@images_file) do |f|
      magic, n_images = f.read(8).unpack('N2')
      raise 'This is not the MNIST image file' unless magic == 2051

      n_rows, n_cols = f.read(8).unpack('N2')
      n_images.times do
        images << f.read(n_rows * n_cols).unpack('C*').map { |value| normalize(value) }
      end
    end

    images
  end

  def label_data
    Zlib::GzipReader.open(@labels_file) do |f|
      magic, n_labels = f.read(8).unpack('N2')
      raise 'This is not the MNIST label file' unless magic == 2049

      return f.read(n_labels).unpack('C*')
    end
  end

  def normalize(value)
    value < 180 ? 0 : 1
  end
end

# MNISTParser.training_set.get_data(1).each { |image| puts image }
