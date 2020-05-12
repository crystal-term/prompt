# require "./timer"
require "./question"

module Term
  class Prompt
    class Keypress < Question
      property keys : Array(String)

      def initialize(prompt, echo = nil, keys = nil, **options)
        super(prompt, **options)
        @echo = echo || false
        @keys = keys ? keys.map(&.to_s) : [] of String

        Term::Reader.subscribe(:keypress)
      end

      def any_key?
        @keys.empty?
      end

      def keypress(key, event)
        if any_key?
          @done = true
        elsif @keys.includes?(event.key.name)
          @done = true
        else
          @done = false
        end
      end

      def process_input(question)
        @prompt.print(render_question)
        until @done; @input = @prompt.read_keypress; end
        Result.new(self, @input.to_s).process
      end

      def refresh(lines, lines_to_clear)
        @prompt.clear_lines(lines)
      end
    end
  end
end
