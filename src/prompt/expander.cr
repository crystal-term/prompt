module Term
  class Prompt
    # A class responsible for rendering expanding options
    # Used by `Prompt` to display key options question.
    class Expander
      enum Status
        Collapsed
        Expanded
      end

      HELP_CHOICE = {
        key: "h",
        name: "print help",
        value: "help"
      }

      getter prefix : String
      getter default : Int32
      getter auto_hint : Bool
      getter palette : Prompt::Palette
      getter selected : Choice?
      getter done : Bool
      getter status : Expander::Status
      getter hint : String?
      getter default_key : Bool
      getter question : String?

      # Create instance of Expander
      def initialize(prompt : Term::Prompt,
                     @prefix = prompt.prefix,
                     @default = 1,
                     @auto_hint = false,
                     @palette = prompt.palette)
        @prompt       = prompt
        @choices      = Choices.new
        @selected     = nil
        @done         = false
        @status       = Status::Collapsed
        @hint         = nil
        @default_key  = false

        Term::Reader.subscribe(:enter, :return, :keypress)
      end

      def expanded?
        @status == Status::Expanded
      end

      def collapsed?
        @status == Status::Collapsed
      end

      def expand
        @status = Status::Expanded
      end

      # Respond to submit event
      def keyenter
        if @input.nil? || @input.to_s.empty?
          @input = @choices[@default - 1].key
          @default_key = true
        end

        selected = select_choice(@input)

        if selected && selected.key.to_s == "h"
          expand
          @selected = nil
          @input = ""
        elsif selected
          @done = true
          @selected = selected
          @hint = nil
        else
          @input = ""
        end
      end

      def keyreturn
        keyenter
      end

      # Respond to key press event
      #
      # @api public
      def keypress(key, event)
        if ["backspace", "delete"].includes?(event.key.name)
          @input = @input.to_s.rchop unless @input.to_s.empty?
        elsif event.value =~ /^[^\e\n\r]/
          @input = @input.to_s + event.value
        end

        @selected = selected = select_choice(@input)
        if selected && !@default_key && collapsed?
          @hint = selected.name
        end
      end

      # Select choice by given key
      def select_choice(key)
        @choices.find { |choice| choice.key == key }
      end

      # Set default value.
      def default(value = (not_set = true))
        return @default if not_set
        @default = value
      end

      # Add a single choice
      def choice(*args, **kwargs)
        @choices << Choice.new(*args, **kwargs)
      end

      # Add choices
      def choices(*values)
        @filter_cache = {} of String => Array(Choice)
        values.each do |value|
          case value
          when Array
            value.each { |v| @choices << Choice.from(v) }
          else
            @choices << Choice.from(value)
          end
        end
      end

      # Get choices
      def choices
        if !filterable? || @filter.empty?
          @choices
        else
          filter_value = @filter.join.downcase
          @filter_cache[filter_value] ||= @choices.select do |choice|
            !choice.disabled? && choice.name.downcase.includes?(filter_value)
          end
        end
      end

      # Execute this prompt
      def call(message, possibilities, &block : self ->)
        choices(possibilities)
        @question = message
        block.call(self)
        setup_defaults
        choice(**HELP_CHOICE)
        render
      end

      # ditto
      def call(message, possibilities)
        call(message, possibilities) { }
      end

      # Create possible keys with current choice highlighted
      private def possible_keys
        keys = @choices.map(&.key).compact
        default_key = keys[@default - 1]
        if selected = @selected
          index = keys.index(selected.key).not_nil!
          keys[index] = @prompt.decorate(keys[index], @palette.active)
        elsif @input.to_s.empty? && default_key
          keys[@default - 1] = @prompt.decorate(default_key, @palette.active)
        end
        keys.join(',')
      end

      private def render
        @input = ""
        until @done
          question = render_question
          @prompt.print(question)
          read_input
          @prompt.print(refresh(question.lines.size))
        end
        @prompt.print(render_question)
        answer
      end

      private def answer
        if selected = @selected
          selected.value
        end
      end

      # Render message with options
      private def render_header
        String.build do |str|
          str << "#{@prefix}#{@question} "
          if @done
            selected_item = @selected.not_nil!.name
            str << @prompt.decorate(selected_item, @palette.active)
          elsif collapsed?
            str << %[(enter "h" for help) ]
            str << "[#{possible_keys}] "
            str << @input
          end
        end
      end

      # Show hint for selected option key
      private def render_hint
        "\n" + @prompt.decorate(">> ", @palette.active) +
          @hint.to_s +
          @prompt.cursor.prev_line +
          @prompt.cursor.forward(Cor.strip(render_header).size)
      end

      # Render question with menu
      private def render_question
        load_auto_hint if @auto_hint
        String.build do |str|
          str << render_header
          str << render_hint if @hint
          str << "\n" if @done

          if !@done && expanded?
            str << render_menu
            str << render_footer
          end
        end
      end

      private def load_auto_hint
        if @hint.nil? && collapsed?
          if selected = @selected
            @hint = selected.name
          else
            if @input.to_s.empty?
              @hint = @choices[@default - 1].name
            else
              @hint = "invalid option"
            end
          end
        end
      end

      private def render_footer
        "  Choice [#{@choices[@default - 1].key}]: #{@input}"
      end

      def read_input
        @prompt.read_keypress
      end

      # Refresh the current input
      private def refresh(lines)
        if (@hint && (!@selected || @done)) || (@auto_hint && collapsed?)
          @hint = nil
          @prompt.clear_lines(lines, :down) +
            @prompt.cursor.prev_line
        elsif expanded?
          @prompt.clear_lines(lines)
        else
          @prompt.clear_line
        end
      end

      # Render help menu
      private def render_menu
        output = ["\n"]
        @choices.each do |choice|
          chosen = %(#{choice.key} - #{choice.name})
          if (selected = @selected) && (selected.key == choice.key)
            chosen = @prompt.decorate(chosen, @palette.active)
          end
          output << "  " + chosen + "\n"
        end
        output.join
      end

      private def setup_defaults
        # validate_choices
      end
    end # Expander
  end # Prompt
end # Term
