module Term
  class Prompt
    class Multiline < Question
      HELP = "(Press CTRL-D or CTRL-Z to finish)"

      property help : String

      def initialize(prompt, help = HELP, **options)
        super(prompt, **options)
        @help = help
        @first_render = true
        @lines_count = 0

        Term::Reader.subscribe(:return, :enter)
      end

      def read_input
        @prompt.read_multiline
      end

      def keyreturn
        @lines_count += 1
      end

      def keyenter
        keyreturn
      end

      def render_question
        String.build do |str|
          str << "#{@prefix}#{@question} "
          if !echo?
            # nop
          elsif @done
            str << @prompt.decorate("#{@input}", @palette.active)
          elsif @first_render
            str << @prompt.decorate(help, @palette.help)
            @first_render = false
          end
          str << "\n"
        end
      end

      def process_input(question)
        @prompt.print(question)
        lines = read_input
        @input = "#{lines.first.strip} ..." unless lines.empty? || lines.first.to_s.empty?
        if @input.nil? && default?
          @input = default
          lines = default
        else
          lines = lines.join
        end
        Result.new(self, lines).process
      end

      def refresh(lines, lines_to_clear)
        size = @lines_count + lines_to_clear + 1
        @prompt.clear_lines(size)
      end
    end
  end
end
