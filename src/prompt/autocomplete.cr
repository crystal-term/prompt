module Term
  class Prompt
    # A class responsible for rendering autocomplete prompt
    # Used by {Prompt} to display interactive autocomplete suggestions.
    #
    # @api private
    class Autocomplete
      HELP = "(Type to search, ↑/↓ to navigate, Enter to select, Tab to complete)"

      property symbols : Hash(Symbol, String)
      property page_size : Int32
      setter help : String?
      property separator : String?

      @prompt : Prompt
      @prefix : String
      @question : String = ""
      @choices : Array(Choice)
      @default : String?
      @active : Int32
      @done : Bool
      @first_render : Bool
      @input : String
      @filtered_choices : Array(Choice)
      @suggestions_cache : Hash(String, Array(Choice))
      @cycle : Bool
      @palette : Palette
      @search_query : String

      def initialize(@prompt : Prompt, **options)
        @prefix = options[:prefix]? || @prompt.prefix
        @default = options[:default]?
        @active = 1
        @done = false
        @first_render = true
        @input = @default.to_s
        @search_query = ""
        @filtered_choices = [] of Choice
        @suggestions_cache = {} of String => Array(Choice)
        @cycle = options[:cycle]? || false
        @palette = options[:palette]? || @prompt.palette
        @symbols = @prompt.symbols.merge(options[:symbols]? || {} of Symbol => String)
        @help = options[:help]?
        @page_size = options[:page_size]? || options[:per_page]? || 10
        @separator = options[:separator]?
        @choices = [] of Choice

        Term::Reader.subscribe(:keypress, :return, :enter, :up, :down, :backspace, :delete, :tab)
      end

      # Set choices
      def choices(values)
        if values.empty?
          @choices = [] of Choice
        else
          values.each do |value|
            @choices << Choice.from(value)
          end
        end
      end

      # Get filtered choices based on current input
      def suggestions
        return @choices if @search_query.empty?
        
        @suggestions_cache[@search_query] ||= @choices.select do |choice|
          !choice.disabled? && choice.name.downcase.includes?(@search_query.downcase)
        end
      end

      # Check if autocomplete is completed
      def completed?
        exact_match = suggestions.find { |choice| choice.name.downcase == @search_query.downcase }
        !exact_match.nil?
      end

      # Call the autocomplete prompt
      def call(question, possibilities, &block : Autocomplete ->)
        choices(possibilities)
        @question = question
        yield self
        render
      end

      # Default help text
      def help
        @help || HELP
      end

      # Handle key events
      def keypress(key, event)
        char = event.value
        
        # Add printable characters to search query and input
        if char =~ /\A[[:print:]]\Z/ && char != "\t" && char != "\n" && char != "\r"
          @search_query += char
          @input = @search_query
          @active = 1
          update_suggestions
        end
      end

      def keybackspace
        return if @search_query.empty?
        
        @search_query = @search_query[0...-1]
        @input = @search_query
        @active = 1
        update_suggestions
      end

      def keydelete
        @search_query = ""
        @input = ""
        @active = 1
        update_suggestions
      end

      def keyup
        return if suggestions.empty?
        
        if @active > 1
          @active -= 1
        elsif @cycle
          @active = suggestions.size
        end
      end

      def keydown
        return if suggestions.empty?
        
        if @active < suggestions.size
          @active += 1
        elsif @cycle
          @active = 1
        end
      end

      def keytab
        return if suggestions.empty?
        
        # Complete with current selection
        if @active <= suggestions.size
          selected = suggestions[@active - 1]
          @search_query = selected.name
          @input = selected.name
          update_suggestions
        end
      end

      def keyenter
        if suggestions.empty? && !@search_query.empty?
          # Allow custom input even if no matches
          @done = true
        elsif @active <= suggestions.size && !suggestions.empty?
          selected = suggestions[@active - 1]
          @input = selected.name
          @done = true
        elsif @search_query.empty? && @default
          @input = @default.to_s
          @done = true
        end
      end

      def keyreturn
        keyenter
      end

      private def update_suggestions
        @suggestions_cache.clear  # Clear cache when search changes
      end

      # Render the autocomplete prompt
      private def render
        @prompt.print(@prompt.hide)
        until @done
          question = render_question
          @prompt.print(question)
          @prompt.read_keypress

          question_lines = question.split(/\r?\n/)
          @prompt.print(refresh(question_lines_size(question_lines)))
        end
        @prompt.print(render_question)
        answer
      ensure
        @prompt.print(@prompt.show)
      end

      # Calculate question lines size
      private def question_lines_size(question_lines)
        question_lines.reduce(0) do |acc, line|
          acc + @prompt.count_screen_lines(line, Term::Screen.width)
        end
      end

      # Get the final answer
      private def answer
        @input
      end

      # Clear screen lines
      private def refresh(lines)
        @prompt.clear_lines(lines)
      end

      # Render the complete question with suggestions
      private def render_question
        String.build do |str|
          str << "#{@prefix}#{@question} #{render_header}\n"
          
          # Show current input
          str << @prompt.decorate("❯ #{@input}", @palette.active)
          str << @prompt.decorate("█", @palette.active) unless @done
          str << "\n"
          
          # Show suggestions
          if !suggestions.empty? && !@done
            suggestions.each_with_index do |choice, index|
              if index + 1 == @active
                str << @prompt.decorate("  #{@symbols[:marker]} #{choice.name}", @palette.active)
              else
                str << "    #{choice.name}"
              end
              str << "\n" unless index == suggestions.size - 1
            end
          elsif !@search_query.empty? && suggestions.empty? && !@done
            str << @prompt.decorate("  No matches found", @palette.help)
          end
        end
      end

      # Render header with help or status
      private def render_header
        if @done
          ""
        elsif @first_render
          @first_render = false
          @prompt.decorate(help, @palette.help)
        else
          ""
        end
      end
    end
  end
end