module Term
  class Prompt
    # A class responsible for rendering select list menu
    # Used by {Prompt} to display interactive menu.
    #
    # @api private
    class List
      HELP = "(Use %s arrow%s keys, press Enter to select%s)"

      # Allowed keys for filter, along with backspace and canc.
      FILTER_KEYS_MATCHER = /\A([[:alnum:]]|[[:punct:]])\Z/

      property symbols : Hash(Symbol, String)

      property page_size : Int32

      setter help : String?

      property separator : String?

      @choices : Choices
      @question : String?
      @prefix : String
      @default : Array(Int32)
      @palette : Palette
      @cycle : Bool
      @filterable : Bool
      @filter : Array(String)
      @filter_cache : Hash(String, Array(Choice))
      @first_render : Bool
      @done : Bool
      @paginator : Paginator
      @block_paginator : BlockPaginator
      @by_page : Bool
      @paging_changed : Bool

      # Create instance of TTY::Prompt::List menu.
      def initialize(@prompt : Term::Prompt, **options)
        check_options_consistency(options)

        @prefix       = options[:prefix]? || @prompt.prefix
        @separator    = options[:separator]? || nil
        @default      = options.fetch(:default) { [] of Int32 }
        @choices      = Choices.new
        @palette      = options[:palette]? || @prompt.palette
        @cycle        = options[:cycle]? || false
        @filterable   = options[:filter]? || false
        @symbols      = @prompt.symbols.merge(options[:symbols]? || {} of Symbol => String)
        @filter       = [] of String
        @filter_cache = {} of String => Array(Choice)
        @help         = options[:help]?
        @first_render = true
        @done         = false
        @page_size    = options[:page_size]? || options[:per_page]? || Paginator::DEFAULT_PAGE_SIZE
        @paginator    = Paginator.new
        @block_paginator = BlockPaginator.new
        @by_page      = false
        @paging_changed = false

        Term::Reader.subscribe(:keypress, :return, :up, :down, :left, :right)
      end

      # Set default option selected
      def default=(value)
        @default.clear
        @default << value
      end

      def default
        @default.first
      end

      # Select paginator based on the current navigation key
      def paginator
        @by_page ? @block_paginator : @paginator
      end

      # Synchronize paginators start positions
      def sync_paginators
        if @by_page
          if @paginator.start_index
            @block_paginator.reset!
            @block_paginator.start_index = @paginator.start_index
          end
        else
          if @block_paginator.start_index
            @paginator.reset!
            @paginator.start_index = @block_paginator.start_index
          end
        end
      end

      # Check if list is paginated
      def paginated?
        choices.size > page_size
      end

      def help
        @help || default_help
      end

      # Information about arrow keys
      def arrows_help
        up_down = @symbols[:arrow_up] + "/" + @symbols[:arrow_down]
        left_right = @symbols[:arrow_left] + "/" + @symbols[:arrow_right]

        arrows = [up_down]
        arrows << " and " if paginated?
        arrows << left_right if paginated?
        arrows.join
      end

      # Default help text
      def default_help
        # Note that enumeration and filter are mutually exclusive
        tokens = if enumerate?
                   {" or number (1-#{choices.size})", ""}
                 elsif filterable?
                   {"", ", and letter keys to filter"}
                 else
                   {"", ""}
                 end

        sprintf(HELP, arrows_help, *tokens)
      end

      # Add a single choice
      def choice(value)
        choices(value)
      end

      # Add choices
      def choices(*values)
        @filter_cache = {} of String => Array(Choice)
        values.each do |value|
          if value.is_a?(Array)
            value.each { |v| @choices << v }
          else
            @choices << value
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

      # Call the list menu by passing question and choices
      def call(question, possibilities, &block : List ->)
        choices(possibilities)
        @question = question
        block.call(self)
        setup_defaults
        render
      end

      def call(question, possibilities)
        call(question, possibilities) { }
      end

      # Check if list is enumerated
      def enumerate?
        !@separator.nil?
      end

      def keynum(key)
        return unless enumerate?

        value = key.to_i
        return unless (1..choices.size).covers?(value)
        return if choices[value - 1].disabled?
        @active = value
      end

      def keyreturn
        @done = true unless choices.empty?
      end

      def search_choice_in(searchable)
        searchable.find { |i| !choices[i - 1].disabled? }
      end

      def keyup
        searchable  = (@active.not_nil! - 1).downto(1).to_a
        prev_active = search_choice_in(searchable)

        if prev_active
          @active = prev_active
        elsif @cycle
          searchable  = choices.size.downto(1).to_a
          prev_active = search_choice_in(searchable)

          @active = prev_active if prev_active
        end

        @paging_changed = @by_page
        @by_page = false
      end

      def keydown
        searchable  = ((@active .not_nil!+ 1)..choices.size)
        next_active = search_choice_in(searchable)

        if next_active
          @active = next_active
        elsif @cycle
          searchable = (1..choices.size)
          next_active = search_choice_in(searchable)

          @active = next_active if next_active
        end
        @paging_changed = @by_page
        @by_page = false
      end

      # Moves all choices page by page keeping the current selected item
      # at the same level on each page.
      #
      # When the choice on a page is outside of next page range then
      # adjust it to the last item, otherwise leave unchanged.
      def keyright
        if (@active.not_nil! + page_size) <= @choices.size
          searchable = ((@active.not_nil! + page_size)..choices.size)
          @active = search_choice_in(searchable)
        elsif @active.not_nil! <= @choices.size # last page shorter
          current   = @active.not_nil! % page_size
          remaining = @choices.size % page_size
          if current.zero? || (remaining > 0 && current > remaining)
            searchable = @choices.size.downto(0).to_a
            @active = search_choice_in(searchable)
          elsif @cycle
            searchable = ((current.zero? ? page_size : current)..choices.size)
            @active = search_choice_in(searchable)
          end
        end

        @paging_changed = !@by_page
        @by_page = true
      end

      def keyleft
        if (@active.not_nil! - page_size) > 0
          searchable = ((@active.not_nil! - page_size)..choices.size)
          @active = search_choice_in(searchable)
        elsif @cycle
          searchable = @choices.size.downto(1).to_a
          @active = search_choice_in(searchable)
        end
        @paging_changed = !@by_page
        @by_page = true
      end

      def keypress(key, event)
        if filterable? && key =~ FILTER_KEYS_MATCHER
          @filter.not_nil! << key.not_nil!
          @active = 1
        end

        if key.to_s.match(/\d/)
          keynum(key.to_s)
        end
      end

      def keydelete
        return unless filterable?

        @filter.clear
        @active = 1
      end

      def keybackspace
        return unless filterable?

        @filter.pop?
        @active = 1
      end

      private def check_options_consistency(options)
        if options.has_key?(:enum) && options.has_key?(:filter)
          raise ArgumentError.new "Enumeration can't be used with filter"
        end
      end

      # Setup default option and active selection
      private def setup_defaults
        validate_defaults

        if !@default.empty?
          @active = @default.first
        else
          @active = (@choices.index { |choice| !choice.disabled? } || 0) + 1
        end
      end

      # Validate default indexes to be within range
      private def validate_defaults
        @default.each do |d|
          msg = if d.nil? || d.to_s.empty?
                  "default index must be an integer in range (1 - #{choices.size})"
                elsif d < 1 || d > choices.size
                  "default index `#{d}` out of range (1 - #{choices.size})"
                elsif choices[d - 1] && choices[d - 1].disabled?
                  "default index `#{d}` matches disabled choice item"
                end

          raise ArgumentError.new(msg) if msg
        end
      end

      # Render a selection list.
      #
      # By default the result is printed out.
      private def render
        @prompt.print(@prompt.hide)
        until @done
          question = render_question
          @prompt.print(question)
          @prompt.read_keypress

          # Split manually; if the second line is blank (when there are no
          # matching lines), it won't be included by using String#lines.
          question_lines = question.split(/\r?\n/)
          @prompt.print(refresh(question_lines_size(question_lines)))
        end
        @prompt.print(render_question)
        answer
      ensure
        @prompt.print(@prompt.show)
      end

      # size how many screen lines the question spans
      private def question_lines_size(question_lines)
        question_lines.reduce(0) do |acc, line|
          acc + @prompt.count_screen_lines(line)
        end
      end

      # Find value for the choice selected
      private def answer
        choices[@active.not_nil! - 1].value
      end

      # Clear screen lines
      private def refresh(lines)
        @prompt.clear_lines(lines)
      end

      # Render question with instructions and menu
      private def render_question
        String.build do |str|
          str << "#{@prefix}#{@question} #{render_header}\n"
          @first_render = false
          unless @done
            str << render_menu
          end
        end
      end

      # Is filtering enabled?
      private def filterable?
        @filterable
      end

      # Header part showing the current filter
      private def filter_help
        "(Filter: #{@filter.join.inspect})"
      end

      # Render initial help and selected choice
      private def render_header
        if @done
          selected_item = choices[@active.not_nil! - 1].name
          @prompt.decorate(selected_item.to_s, @palette.active)
        elsif @first_render
          @prompt.decorate(help, @palette.help)
        elsif filterable? && @filter.any?
          @prompt.decorate(filter_help, @palette.help)
        end
      end

      # Render menu with choices to select from
      private def render_menu
        output = [] of String

        sync_paginators if @paging_changed
        paginator.paginate(choices, @active.not_nil!, @page_size) do |choice, index|
          num = enumerate? ? (index + 1).to_s + @separator.to_s + " " : ""
          message = if index + 1 == @active.not_nil! && !choice.disabled?
                      selected = "#{@symbols[:marker]} #{num}#{choice.name}"
                      @prompt.decorate(selected.to_s, @palette.active)
                    elsif choice.disabled?
                      @prompt.decorate(@symbols[:cross], :red) +
                        " #{num}#{choice.name} #{choice.disabled}"
                    else
                      "  #{num}#{choice.name}"
                    end
          end_index = paginated? ? paginator.end_index : choices.size - 1
          newline = (index == end_index) ? "" : "\n"
          output << (message + newline)
        end

        output.join
      end
    end # List
  end
end
