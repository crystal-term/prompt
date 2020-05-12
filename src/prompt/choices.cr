require "./choice"

module Term
  class Prompt
    # A class responsible for storing a collection of choices
    #
    # @api private
    class Choices
      include Enumerable(Choice)

      # The actual collection choices
      getter choices : Array(Choice)

      delegate :each, :size, :size, :to_a, :empty?, :values_at, :index, to: @choices

      # Convenience for creating choices
      def self.[](*choices)
        new(choices)
      end

      # Create Choices collection
      def initialize(choices = [] of String)
        @choices = [] of Choice
        choices.each do |choice|
          @choices << Choice.from(choice)
        end
      end

      # Add choice to collection
      def <<(choice)
        choices << Choice.from(choice)
      end

      # Access choice by index
      def [](index)
        @choices[index]
      end

      def []?(index)
        @choices[index]?
      end

      # Pluck a choice by its name from collection
      # def pluck(name)
      #   map { |choice| choice.public_send(name) }
      # end

      # Find a matching choice
      # def find_by(attr, value)
      #   find { |choice| choice.public_send(attr) == value }
      # end
    end
  end
end
