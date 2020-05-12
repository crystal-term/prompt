module Term
  class Prompt
    class AnswersCollector
      alias Answers = String? | Array(Answers) | Hash(String, Answers)

      getter! name : String?

      # Initialize answer collector
      def initialize(@prompt : Term::Prompt, **options)
        @answers = {} of String => Answers
        @name = nil

        if answers = options[:answers]?
          @answers = @answers.merge(answers)
        end
      end

      # Start gathering answers
      def call(&block : AnswersCollector ->)
        with self yield self
        @answers
      end

      # Create answer entry
      def key(name, &block : AnswersCollector ->)
        @name = name.to_s
        answer = create_collector.call(&block)
        add_answer(answer)
        self
      end

      # ditto
      def key(name)
        @name = name.to_s
        self
      end

      # Change to collect all values for a key
      def values(&block)
        @answers[name] = [@answers[name]]
        answer = create_collector.call(&block)
        add_answer(answer)
        self
      end

      # ditto
      def values
        @answers[name] = [@answers[name]]
        self
      end

      private def create_collector
        self.class.new(@prompt)
      end

      private def add_answer(answer)
        if @answers[name]? && @answers[name].is_a?(Array)
          @answers[name].as(Array) << answer
        else
          @answers[name] = answer
        end
      end

      macro method_missing(call)
        {% begin %}
          {% if Term::Prompt.has_method?(call.name.id.symbolize) %}
            answer = @prompt.{{ call.name.id }}(\
              {{ call.args.join(", ").id }},
              {% if call.named_args %}{{ call.named_args.map { |a| "#{a.name.id}: #{a.value.id}" }.join(", ").id }}{% end %}
              {% if call.block_arg %}{{ call.block_arg }}{% end %}\
            )
            add_answer(answer)
          {% else %}
            {% raise "Method #{call.name.id} does not exist on Term::Prompt" %}
          {% end %}
        {% end %}
      end
    end
  end
end
