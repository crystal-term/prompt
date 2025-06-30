require "./list"

module Term
  class Prompt
    # A class responsible for rendering multi select list menu.
    # Used by {Prompt} to display interactive choice menu.
    class MultiList < List
      HELP = "(Use %s arrow%s keys, press Space to select and Enter to finish%s)"

      property min : Int32?
      property max : Int32?

      @echo : Bool
      @help : String?

      # Create instance of TTY::Prompt::MultiList menu.
      def initialize(prompt, **options)
        super
        @selected = [] of Choice
        @help = options[:help]?
        @echo = options[:echo]?.nil? ? true : !!options[:echo]?
        @min  = options[:min]?
        @max  = options[:max]?

        Term::Reader.subscribe(:space)
      end

      # Callback fired when enter/return key is pressed
      def keyreturn
        if min = @min
          super if @selected.size >= min
        else
          super
        end
      end

      def keyenter
        keyreturn
      end

      # Callback fired when space key is pressed
      def keyspace
        active_choice = choices[@active.not_nil! - 1]
        if @selected.includes?(active_choice)
          @selected.delete(active_choice)
        else
          return if @max && @selected.size >= @max.not_nil!
          @selected << active_choice
        end
      end

      # Setup default options and active selection
      def setup_defaults
        validate_defaults
        # At this stage, @choices matches all the visible choices.
        @selected = @default.map { |d| d - 1 }.map { |i| @choices[i] }

        if !@default.empty?
          @active = @default.last
        else
          @active = (@choices.index { |choice| !choice.disabled? } || 0) + 1
        end
      end

      # Generate selected items names
      def selected_names
        @selected.map(&.name).join(", ")
      end

      # Header part showing the minimum/maximum number of choices
      #
      # @return [String]
      #
      # @api private
      def minmax_help
        help = [] of String
        help << "min. #{@min}" if @min
        help << "max. #{@max}" if @max
        "(%s) " % [ help.join(" ") ]
      end

      # Render initial help text and then currently selected choices
      def render_header
        instructions = @prompt.decorate(help, @palette.help)
        minmax_suffix = @min || @max ? minmax_help : ""

        if @done && @echo
          @prompt.decorate(selected_names, @palette.active)
        elsif @selected.size > 0 && @echo
          help_suffix = filterable? && @filter.any? ? " #{filter_help}" : ""
          minmax_suffix + selected_names +
            (@first_render ? " #{instructions}" : help_suffix)
        elsif @first_render
          minmax_suffix + instructions
        elsif filterable? && @filter.any?
          minmax_suffix + filter_help
        elsif @min || @max
          minmax_help
        end
      end

      # All values for the choices selected
      def answer
        @selected.map(&.value)
      end

      # Render menu with choices to select from
      def render_menu
        output = [] of String

        sync_paginators if @paging_changed
        paginator.paginate(choices, @active.not_nil!, @page_size) do |choice, index|
          num = enumerate? ? (index + 1).to_s + @separator.not_nil! + " " : ""
          indicator = (index + 1 == @active.not_nil!) ?  @symbols[:marker] : " "
          indicator += " "
          message = if @selected.includes?(choice) && !choice.disabled?
                      selected = @prompt.decorate(@symbols[:radio_on], @palette.active)
                      "#{selected} #{num}#{choice.name}"
                    elsif choice.disabled?
                      @prompt.decorate(@symbols[:cross], :red) +
                        " #{num}#{choice.name} #{choice.disabled}"
                    else
                      "#{@symbols[:radio_off]} #{num}#{choice.name}"
                    end
          end_index = paginated? ? paginator.end_index : choices.size - 1
          newline = (index == end_index) ? "" : "\n"
          output << indicator + message + newline
        end

        output.join
      end
    end # MultiList
  end
end
