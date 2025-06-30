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
        # If ctrl_c is in the allowed keys, use :noop to prevent interrupt
        interrupt = @keys.includes?("ctrl_c") ? :noop : nil
        until @done
          @input = @prompt.reader.read_keypress(interrupt: interrupt)
        end
        Result.new(self, @input.to_s).process
      end

      def refresh(lines, lines_to_clear)
        @prompt.clear_lines(lines)
      end
    end
  end
end
