# frozen_string_literal: true

require 'matrix'
require_relative 'digit'
require_relative 'mnist_parser'
require 'rroc'

class MNIST
  THRESHOLD = 0
  STIMULUS_AMOUNT = 784
  NEURONS = 10
  DECAY = 1
  SYNAPSE_INCREASE = 20
  BRAIN_MAX = 101
  TEST_DIGIT = 4
  TRANCHE_AMOUNT = 6 # A single tranche is a set of 10 digits, one of each
  TESTING_NBR_AMOUNT = 20
  TESTING_NON_NBR_AMOUNT = 20
  TRIALS = 1

  def initialize
    @mnist_train_data = MNISTParser.training_set
    @mnist_test_data = MNISTParser.test_set
  end

  def run
    puts "Beginning to run #{TRIALS} trials"
    TRIALS.times do |trial|
      get_auc(trial)
      write_brain_to_file("brain_#{trial}.txt")
    end
  end

  def get_auc(trial)
    @train_digits = tranche(TRANCHE_AMOUNT)
    @test_digits = @mnist_test_data.get_exact_nbr(TEST_DIGIT, TESTING_NBR_AMOUNT, TESTING_NON_NBR_AMOUNT)
    @brain = Matrix.build(10, 784) { 1 }
    puts "Beginning trial number ##{trial + 1}"
    train
    display_neuron(TEST_DIGIT)
    auc = ROC.auc(test)
    puts "Outputting AUC from program: #{auc}"
  end

  def train
    puts 'Training...'
    @train_digits.each do |digit|
      learn(digit.label, digit.image)
      decay(digit.label)
      # puts "Printing out affected neuron #{digit.label}, sum: #{neuron(digit.label).sum}"
    end
    puts 'Training complete.'
  end

  def test
    classifiers = []
    puts 'Testing...'
    @test_digits.each do |digit|
      behavior = @brain * digit.image
      classifiers << [behavior[TEST_DIGIT, 0], digit.label == TEST_DIGIT ? 1 : -1]
      puts "#{digit.label} : #{classifiers[-1][0]} : #{classifiers[-1][1]}"
    end
    puts 'Testing complete.'
    classifiers
  end

  def output_brain
    @brain.to_a.each_with_index do |neuron, neuron_idx|
      puts "Displaying neuron #{neuron_idx}"
      displays_neuron(neuron)
      puts
    end
  end

  def display_neuron(neuron_idx)
    displays_neuron(neuron(neuron_idx))
  end

  def write_brain_to_file(filename)
    File.open(filename, 'w') do |f|
      @brain.to_a.each do |neuron|
        neuron.each_with_index do |val, idx|
          f.write(val)
          f.write(' ') unless idx == neuron.length - 1
        end
        f.write("\n")
      end
    end
  end

  def read_brain_from_file(filename)
    brain = Matrix.build(10, 784) { 1 }
    File.foreach(filename).with_index do |line, y|
      line.split(' ').each_with_index do |val, x|
        brain[y, x] = val.to_i
      end
    end
    brain
  end

  private

  def tranche(nbr)
    tranche = []
    nbr.times { tranche.concat(@mnist_train_data.get_one_of_each_nbr) }
    tranche
  end

  def learn(neuron, image)
    STIMULUS_AMOUNT.times do |synapse|
      @brain[neuron, synapse] += SYNAPSE_INCREASE if image[synapse, 0].positive? && @brain[neuron, synapse] < BRAIN_MAX
    end
  end

  def decay(neuron)
    10.times do |idx|
      next if idx == neuron

      STIMULUS_AMOUNT.times { |synapse| @brain[idx, synapse] -= DECAY if @brain[idx, synapse] > 1 }
    end
  end

  def displays_neuron(neuron)
    neuron.each_with_index do |val, idx|
      puts if (idx % 28).zero? && idx.positive?
      print val
      print ' '
    end
    puts
  end

  def neuron(neuron_idx)
    @brain.to_a[neuron_idx]
  end

  def classifiers_from_file(filename)
    File.open(filename).readlines.map { |l| l.strip.split(',').map(&:to_i) }
  rescue StandardError
    puts 'File does not exist or is invalid'
    exit
  end
end

MNIST.new.run
