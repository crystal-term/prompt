module Term
  class Prompt
    # Accumulates errors
    class Result
      getter question : Question

      getter value : String?

      def initialize(@question, @value)
      end

      def process
        results = [] of Bool
        @question.validators.each do |v|
          results << v.call(@question, @value)
        end

        if results.all?
          Success.new(@question, @value)
        else
          Failure.new(@question, @value)
        end
      end

      def success?
        is_a?(Success)
      end

      def failure?
        is_a?(Failure)
      end

      class Success < Result; end

      class Failure < Result; end
    end
  end
end
