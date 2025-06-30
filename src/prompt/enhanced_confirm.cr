module Term
  class Prompt
    # A class responsible for rendering enhanced confirmation prompts
    # Used by {Prompt} to display confirmation with destructive operation support.
    #
    # @api private
    class EnhancedConfirm
      DESTRUCTIVE_HELP = "(Type 'yes' to confirm destructive action)"
      CONFIRM_HELP = "(Type 'yes' to confirm)"
      DOUBLE_CONFIRM_HELP = "(Type 'yes' twice to confirm)"

      @prompt : Prompt
      @prefix : String
      @question : String = ""
      @destructive : Bool
      @double_confirm : Bool
      @confirmation_word : String
      @done : Bool
      @first_render : Bool
      @input : String
      @confirmations : Array(String)
      @palette : Palette
      @require_exact : Bool
      @warning_message : String?

      def initialize(@prompt : Prompt, **options)
        @prefix = options[:prefix]? || @prompt.prefix
        @destructive = options[:destructive]? || false
        @double_confirm = options[:double_confirm]? || false
        @confirmation_word = options[:confirmation_word]?.try(&.to_s) || "yes"
        @require_exact = @destructive || @double_confirm || options[:require_exact]? || false
        @warning_message = options[:warning]?.try(&.to_s)
        @done = false
        @first_render = true
        @input = ""
        @confirmations = [] of String
        @palette = options[:palette]? || @prompt.palette

        Term::Reader.subscribe(:keypress, :return, :enter, :backspace, :delete)
      end

      # Call the enhanced confirmation prompt
      def call(question, &block : EnhancedConfirm ->)
        @question = question
        yield self if block
        render
      end

      # Handle key events
      def keypress(key, event)
        char = event.value
        
        # Add printable characters to input
        if char =~ /\A[[:print:]]\Z/ && char != "\n" && char != "\r"
          @input += char
        end
      end

      def keybackspace
        return if @input.empty?
        @input = @input[0...-1]
      end

      def keydelete
        @input = ""
      end

      def keyenter
        if @require_exact
          if @input.downcase == @confirmation_word.downcase
            if @double_confirm
              @confirmations << @input
              @input = ""
              
              if @confirmations.size >= 2
                @done = true
              end
            else
              @done = true
            end
          else
            # Wrong input, clear and try again
            @input = ""
          end
        else
          # Simple yes/no logic
          case @input.downcase
          when "y", "yes", "true", "1"
            @done = true
          when "n", "no", "false", "0"
            @done = true
          else
            @input = ""
          end
        end
      end

      def keyreturn
        keyenter
      end

      # Get the confirmation result
      def result
        if @require_exact
          return true if @confirmations.size >= 2 && @double_confirm
          return @input.downcase == @confirmation_word.downcase
        else
          case @input.downcase
          when "y", "yes", "true", "1"
            true
          else
            false
          end
        end
      end

      # Render the enhanced confirmation prompt
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
        @prompt.print("\n")  # Add newline after final result
        result
      ensure
        @prompt.print(@prompt.show)
      end

      # Calculate question lines size
      private def question_lines_size(question_lines)
        question_lines.reduce(0) do |acc, line|
          acc + @prompt.count_screen_lines(line, Term::Screen.width)
        end
      end

      # Clear screen lines
      private def refresh(lines)
        @prompt.clear_lines(lines)
      end

      # Render the complete question
      private def render_question
        String.build do |str|
          str << "#{@prefix}#{@question} #{render_header}\n"
          
          unless @done
            # Show warning if destructive
            if @destructive && @warning_message
              str << @prompt.decorate("⚠️  #{@warning_message}", @palette.error)
              str << "\n"
            elsif @destructive
              str << @prompt.decorate("⚠️  This action cannot be undone!", @palette.error)
              str << "\n"
            end
            
            # Show double confirmation progress
            if @double_confirm && !@confirmations.empty?
              str << @prompt.decorate("First confirmation received. Please confirm again:", @palette.help)
              str << "\n"
            end
            
            # Show input prompt
            if @destructive || @require_exact
              color = @destructive ? @palette.error : @palette.active
              str << @prompt.decorate("Type '#{@confirmation_word}' to confirm: ", color)
            else
              str << "Confirm (y/n): "
            end
            
            # Show current input
            str << @input
            str << @prompt.decorate("█", @palette.active) unless @done
          else
            # Show result
            if result
              str << @prompt.decorate("✓ Confirmed", @palette.active)
            else
              str << @prompt.decorate("✗ Cancelled", @palette.help)
            end
          end
        end
      end

      # Render header with help
      private def render_header
        if @done
          ""
        elsif @first_render
          @first_render = false
          help_text = if @double_confirm
            DOUBLE_CONFIRM_HELP
          elsif @destructive || @require_exact
            @destructive ? DESTRUCTIVE_HELP : CONFIRM_HELP
          else
            "(y/N)"
          end
          @prompt.decorate(help_text, @palette.help)
        else
          ""
        end
      end
    end
  end
end