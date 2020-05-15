module Term
  class Prompt
    class MaskQuestion < Question
      property mask : String

      def initialize(prompt, mask = nil, **options)
        super(prompt, **options)
        @mask = mask || prompt.symbols[:dot]
        @done_masked = false
        @failure = false

        Term::Reader.subscribe(:keypress, :return, :enter)
      end

      # Call the question.
      def call(message = "", &block : MaskQuestion ->)
        @done = false
        @question = message
        block.call(self)
        render
      end

      def keyreturn
        @done_masked = true
      end

      def keyenter
        @done_masked = true
      end

      def keypress(key, event)
        if %w(backspace delete).includes?(event.key.name)
          @input = @input.not_nil!.rchop unless @input.to_s.empty?
        elsif event.value =~ /^[^\e\n\r]/
          @input = @input.to_s + event.value
        end
      end

      def render_question
        String.build do |str|
          str << "#{@prefix}#{@question} "
          if echo?
            masked = @mask * @input.to_s.size
            if @done_masked && !@failure
              str << @prompt.decorate(masked, @palette.active)
            elsif @done_masked && @failure
              str << @prompt.decorate(masked, @palette.error)
            else
              str << masked
            end
          end
          str << "\n" if @done
        end
      end

      def render_error(errors)
        @failure = !errors.empty?
        super
      end

      def read_input(question)
        @done_masked = false
        @failure = false
        @input = ""
        @prompt.print(question)
        until @done_masked
          @prompt.read_keypress
          question = render_question
          total_lines = @prompt.count_screen_lines(question)
          @prompt.print(@prompt.clear_lines(total_lines))
          @prompt.print(render_question)
        end
        @prompt.puts
        @input
      end
    end
  end
end
