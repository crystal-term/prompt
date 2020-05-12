require "./validator"
require "./question/*"

module Term
  class Prompt
    # A class responsible for gathering user input
    class Question
      include Validators

      getter question : String?

      property prefix : String

      getter validators : Array(Validator | ValidatorProc)

      getter? echo : Bool
      property echo : Bool

      property palette : Palette

      getter value : String?

      getter errors : Array(String)

      getter warnings : Array(String)

      @prompt : Prompt
      @done : Bool
      @first_render : Bool
      @default : String?
      @input : String?

      def initialize(prompt, **options)
        @prompt       = prompt
        @prefix       = options[:prefix]? || @prompt.prefix
        @validators   = [] of Validator | ValidatorProc
        @default      = options[:default]?
        @palette      = options[:palette]? || @prompt.palette
        @echo         = options[:echo]?.nil? ? true : !!options[:echo]?
        @value        = options[:value]?
        @errors       = [] of String
        @warnings     = [] of String
        @input        = @value
        @done         = false
        @first_render = true

        if validators = options[:validators]?
          @validators.concat validators
        end

        required     = options[:required]? || false
        @validators << RequiredValidator.new if required

        min = options[:min_length]?
        max = options[:max_length]?
        @validators << LengthValidator.new(min, max) if min || max

        pattern = options[:match]?
        @validators << PatternValidator.new(pattern) if pattern
      end

      def default?
        !@default.nil?
      end

      def default
        @default
      end

      {% begin %}
        # Call the question.
        def call(message = "", &block : {{ @type.id }} ->)
          @done = false
          @question = message
          block.call(self)
          render
        end
      {% end %}

      # ditto
      def call(message = "")
        call(message) {}
      end

      # Read answer and convert to type
      def render
        until @done
          @errors.clear
          @warnings.clear

          result = process_input(render_question)

          if result.failure?
            unless @errors.empty?
              @prompt.print(render_error(@errors))
            end
          end

          unless @warnings.empty?
            @prompt.print(render_warning(@warnings))
          end

          if result.success?
            @done = true
          end

          question =  render_question
          input_line = question + result.value.to_s
          total_lines = @prompt.count_screen_lines(input_line)
          @prompt.print(refresh(question.lines.size, total_lines))
        end

        @prompt.print(render_question)
        convert_result(result.not_nil!.value)
      end

      # Render question
      private def render_question
        String.build do |str|
          if !prefix.strip.empty? || !@question.to_s.strip.empty?
            str << "#{@prefix}#{@question} "
          end
          if !echo?
            # nop
          elsif @done
            str << @prompt.decorate(@input.to_s, @palette.active)
          elsif @default && !@default.to_s.strip.empty?
            str << @prompt.decorate("(#{@default}) ", @palette.help)
          end
          str << "\n" if @done
        end
      end

      # Decide how to handle input from user
      def process_input(question)
        @input = read_input(question)
        if @input.to_s.strip.empty?
          @input = default? ? default : nil
        end
        Result.new(self, @input).process
      end

      def read_input(question)
        if value = @value
          @first_render = false
          @prompt.read_line(question, echo: @echo, value: value).chomp
        else
          @prompt.read_line(question, echo: @echo).chomp
        end
      end

      def render_error(errors)
        errors.reduce([] of String) do |acc, err|
          acc << @prompt.decorate(">> #{err}", @palette.error)
          acc
        end.join("\n")
      end

      def render_warning(warnings)
        warnings.reduce([] of String) do |acc, wrn|
          acc << @prompt.decorate(">> #{wrn}", @palette.warning)
          acc
        end.join("\n")
      end

      # Determine area of the screen to clear
      def refresh(lines, lines_to_clear)
        String.build do |str|
          if @done
            if @errors.empty? && @warnings.empty?
              str << @prompt.cursor.up(lines)
            else
              lines += @errors.size
              lines += @warnings.size
              lines_to_clear += @errors.size
              lines_to_clear += @warnings.size
            end
          else
            str << @prompt.cursor.up(lines)
          end
          str << @prompt.clear_lines(lines_to_clear)
        end
      end

      def convert_result(value)
        value
      end

      def to_s(io)
        io << @message.to_s
      end

      def inspect
        "#<#{self.class.name} @message=#{message}, @input=#{@input}>"
      end
    end
  end
end
