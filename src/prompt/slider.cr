module Term
  class Prompt
    # A class responsible for gathering numeric input from range
    class Slider
      HELP = "(Use arrow keys, press Enter to select)"

      FORMAT = ":slider %d"

      getter symbols : Hash(Symbol, String)

      @min : Int32
      @max : Int32
      @step : Int32
      @_default : Int32?
      @prefix : String
      @palette : Palette
      @active : Int32
      @question : String?

      # Initailize a Slider
      def initialize(@prompt : Term::Prompt, **options)
        @prefix       = options[:prefix]? || @prompt.prefix
        @min          = options[:min]? || 0
        @max          = options[:max]? || 10
        @step         = options[:step]? || 1
        @_default     = options[:default]?
        @palette      = options[:palette]? || @prompt.palette
        @format       = options[:format]? || FORMAT
        @symbols      = @prompt.symbols.merge(options[:symbols]? || {} of Symbol => String)
        @first_render = true
        @done         = false
        @question     = nil
        @active       = 0

        Term::Reader.subscribe(:return, :enter, :left, :right, :up, :down)
      end

      # Change symbols used by this prompt
      def symbols=(new_symbols)
        @symbols.merge!(new_symbols)
      end

      # Setup initial active position
      def initial
        if @_default.nil?
          range.size // 2
        else
          val = range.index(@_default)
          val || range.size - 1
        end
      end

      # Range of numbers to render
      def range
        (@min..@max).step(@step).to_a
      end

      def default(value)
        @_default = value
      end

      def min(value)
        @min = value
      end

      def max(value)
        @max = value
      end

      def step(value)
        @step = value
      end

      def format(value)
        @format = value
      end

      # Call the slider by passing question
      def call(question, &block)
        @question = question
        block.call(self)
        @active = initial
        render
      end

      # ditto
      def call(question)
        @question = question
        @active = initial
        render.to_i
      end

      def keyleft
        @active -= 1 if @active > 0
      end

      def keydown
        keyleft
      end

      def keyright
        @active += 1 if (@active + 1) < range.size
      end

      def keyup
        keyright
      end

      def keyreturn
        @done = true
      end

      def keyenter
        keyreturn
      end

      # Render an interactive range slider.
      private def render
        @prompt.print(@prompt.hide)
        until @done
          question = render_question
          @prompt.print(question)
          @prompt.read_keypress
          refresh(question.lines.size)
        end
        @prompt.print(render_question)
        answer
      ensure
        @prompt.print(@prompt.show)
      end

      # Clear screen
      private def refresh(lines)
        @prompt.print(@prompt.clear_lines(lines))
      end

      # @return [Integer]
      private def answer
        range[@active]
      end

      # Render question with the slider
      private def render_question
        String.build do |str|
          str << "#{@prefix}#{@question} "
          if @done
            str << @prompt.decorate(answer.to_s, @palette.active)
            str << "\n"
          else
            str << render_slider
          end
          if @first_render
            str << "\n" + @prompt.decorate(HELP, @palette.help)
            @first_render = false
          end
        end
      end

      # Render slider representation
      private def render_slider
        slider = (@symbols[:line] * @active) +
                 @prompt.decorate(@symbols[:bullet], @palette.active) +
                 (@symbols[:line] * (range.size - @active - 1))
        value = " #{range[@active]}"
        @format.gsub(":slider", slider) % [value]
      end
    end
  end
end
