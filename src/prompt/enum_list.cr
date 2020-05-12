module Term
  class Prompt
    class EnumList
      PAGE_HELP = "(Press tab/right or left to reveal more choices)"

      getter input : String?

      getter done : Bool

      property page_help : String

      getter failure : Bool

      property page_size : Int32

      setter default : Int32

      property separator : String

      getter symbols : Hash(Symbol, String)

      getter choices : Choices

      property default : Int32

      @first_render : Bool

      @active : Int32

      @choices : Choices

      @paginator : BlockPaginator

      @page_active : Int32

      @palette : Palette

      @cycle : Bool

      @question : String?

      property prefix : String

      # Create instance of EnumList menu.
      def initialize(@prompt : Term::Prompt, **options)
        @prefix       = options[:prefix]? || @prompt.prefix
        @separator    = options[:separator]? || ")"
        @default      = options[:default]? || -1
        @palette      = options[:palette]? || @prompt.palette
        @cycle        = options[:cycle]? || false
        @symbols      = @prompt.symbols.merge(options[:symbols]? || {} of Symbol => String)
        @input        = nil
        @done         = false
        @first_render = true
        @failure      = false
        @active       = @default
        @choices      = Choices.new
        @page_size    = options[:page_size]? || options[:per_page]? || Paginator::DEFAULT_PAGE_SIZE
        @page_help    = options[:page_help]? || PAGE_HELP
        @paginator    = BlockPaginator.new
        @page_active  = @default

        Term::Reader.subscribe(:keypress, :return, :enter, :right, :left)
      end

      # Change symbols used by this prompt
      def symbols=(new_symbols)
        @symbols.merge!(new_symbols)
      end

      # Check if default value is set
      def default?
        @default && @default.not_nil! > 0
      end

      # Check if list is paginated
      def paginated?
        @choices.size > page_size
      end

      # Add a single choice
      def choice(*value, &block)
        if block
          @choices << (value << block)
        else
          @choices << value
        end
      end

      # Add multiple choices
      def choices=(values)
        values.each { |val| @choices << val }
      end

      # Call the list menu by passing question and choices
      def call(question, possibilities, &block : EnumList ->)
        self.choices = possibilities
        @question = question
        block.call(self)
        setup_defaults
        render
      end

      # ditto
      def call(question, possibilities)
        call(question, possibilities) { }
      end

      def keypress(key, event)
        if %w(backspace delete).includes?(key)
          return if !@input || @input.to_s.empty?
          @input = @input.to_s.rchop
          mark_choice_as_active
        elsif event.value =~ /^\d+$/
          @input = @input.to_s + event.value
          mark_choice_as_active
        end
      end

      def keyreturn
        @failure = false
        num = @input.to_s.to_i? || 0
        choice_disabled = choices[num - 1] && choices[num - 1].disabled?
        choice_in_range = num > 0 && num <= @choices.size

        if choice_in_range && !choice_disabled || (@input && @input.not_nil!.empty?)
          @done = true
        else
          @input = ""
          @failure = true
        end
      end

      def keyenter
        keyreturn
      end

      def keyright
        if (@page_active + page_size) <= @choices.size
          @page_active += page_size
        elsif @cycle
          @page_active = 1
        end
      end

      def keyleft
        if (@page_active - page_size) >= 0
          @page_active -= page_size
        elsif @cycle
          @page_active = @choices.size - 1
        end
      end

      # Find active choice or set to default
      def mark_choice_as_active
        next_active = @choices[(@input.try &.to_i? || 1) - 1]?

        if next_active && next_active.disabled?
          # noop
        elsif (@input.try &.to_i? || 0 > 0) && next_active
          @active = @input.not_nil!.to_i
        else
          @active = @default
        end
        @page_active = @active
      end

      # Validate default indexes to be within range
      def validate_defaults
        msg = if @default.nil? || @default.to_s.empty?
                "default index must be an integer in range (1 - #{choices.size})"
              elsif @default < 1 || @default > @choices.size
                "default index #{@default} out of range (1 - #{@choices.size})"
              elsif choices[@default - 1] && choices[@default - 1].disabled?
                "default index #{@default} matches disabled choice item"
              end

        raise msg if msg
      end

      # Setup default option and active selection
      def setup_defaults
        if !default?
          @default = (0..choices.size).find {|i| !choices[i].disabled? } || 0 + 1
        end
        validate_defaults
        mark_choice_as_active
      end

      # Render a selection list.
      def render
        @input = ""
        until @done
          question = render_question
          @prompt.print(question)
          @prompt.print(render_error) if @failure
          if paginated? && !@done
            @prompt.print(render_page_help)
          end
          @prompt.read_keypress
          question_lines = question.split(/\r?\n/)
          @prompt.print(refresh(question_lines_count(question_lines)))
        end
        @prompt.print(render_question)
        answer
      end

      # Count how many screen lines the question spans
      def question_lines_count(question_lines)
        question_lines.reduce(0) do |acc, line|
          acc + @prompt.count_screen_lines(line)
        end
      end

      # Find value for the choice selected
      def answer
        @choices[@active - 1].value
      end

      # Determine area of the screen to clear
      def refresh(lines)
        @prompt.clear_lines(lines) +
          @prompt.cursor.clear_screen_down
      end

      # Render question with the menu options
      def render_question
        String.build do |str|
          str << "#{@prefix}#{@question} #{render_header}\n"
          unless @done
            str << render_menu
            str << render_footer
          end
        end
      end

      # Error message when incorrect index chosen
      def error_message
        error = "Please enter a valid number"
        "\n" + @prompt.decorate(">>", @palette.error) + " " + error
      end

      # Render error message and return cursor to position of input
      def render_error
        error = error_message
        if !paginated?
          error += @prompt.cursor.prev_line
          error += @prompt.cursor.forward(render_footer.size)
        end
        error
      end

      # Render chosen option
      def render_header
        return "" unless @done
        return "" unless @active
        selected_item = @choices[@active - 1].name.to_s
        @prompt.decorate(selected_item, @palette.active)
      end

      # Render footer for the indexed menu
      def render_footer
        "  Choose 1-#{@choices.size} [#{@default}]: #{@input}"
      end

      # Pagination help message
      def page_help_message
        return "" unless paginated?
        "\n" + @prompt.decorate(@page_help, @palette.help)
      end

      # Render page help
      def render_page_help
        String.build do |str|
          str << page_help_message
          if @failure
            str << @prompt.cursor.prev_line
          end
          str << @prompt.cursor.prev_line
          str << @prompt.cursor.forward(render_footer.size)
        end
      end

      # Render menu with indexed choices to select from
      def render_menu
        output = [] of String

        @paginator.paginate(@choices, @page_active, @page_size) do |choice, index|
          num = (index + 1).to_s + @separator + ' '
          selected = num.to_s + choice.name.to_s
          output << if index + 1 == @active && !choice.disabled?
                      (" " * 2) + @prompt.decorate(selected, @palette.active)
                    elsif choice.disabled?
                      @prompt.decorate(@symbols[:cross], :red) + ' ' +
                      selected + ' ' + choice.disabled.to_s
                    else
                      (" " * 2) + selected
                    end
          output << "\n"
        end

        output.join
      end
    end
  end
end
