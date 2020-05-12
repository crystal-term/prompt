module Term
  class Prompt
    class Paginator
      DEFAULT_PAGE_SIZE = 6

      # The 0-based index of the first item on this page
      property start_index : Int32?

      # The 0-based index of the last item on this page
      getter end_index : Int32?

      # The 0-based index of the active item on this page
      getter current_index : Int32

      # The 0-based index of the previously active item on this page
      getter last_index : Int32

      @page_size : Int32

      # Create a Paginator
      def initialize(**options)
        @last_index    = [options[:default]?].flatten.compact.first? || 0
        @page_size     = options[:page_size]? || options[:per_page]? || DEFAULT_PAGE_SIZE
        @start_index   = [options[:default]?].flatten.compact.first?
        @current_index = 0
      end

      # Reset current page indexes
      def reset!
        @start_index = nil
        @end_index   = nil
      end

      # Check if page size is valid
      def check_page_size!
        raise ArgumentError.new("page_size must be > 0") if @page_size < 1
      end

      # Paginate collection given an active index
      def paginate(list, active, page_size = nil, &block : Choice, Int32 ->)
        current_index = active - 1
        default_size = (list.size <= DEFAULT_PAGE_SIZE ? list.size : DEFAULT_PAGE_SIZE)
        @page_size = page_size || @page_size || default_size
        check_page_size!
        @start_index ||= (current_index // @page_size) * @page_size
        @end_index ||= @start_index.not_nil! + @page_size - 1

        # Don't paginate short lists
        if list.size <= @page_size
          @start_index = 0
          @end_index = list.size - 1
          return list.each_with_index(&block)
        end

        step = (current_index - @last_index).abs
        if current_index > @last_index # going up
          if current_index >= @end_index.not_nil! && current_index < list.size - 1
            last_page = list.size - @page_size
            @start_index = {@start_index.not_nil! + step, last_page}.min
          end
        elsif current_index < @last_index # going down
          if current_index <= @start_index.not_nil! && current_index > 0
            @start_index = {@start_index.not_nil! - step, 0}.max
          end
        end

        # Cycle list
        if current_index.zero?
          @start_index = 0
        elsif current_index == list.size - 1
          @start_index = list.size - 1 - (@page_size - 1)
        end

        @end_index = @start_index.not_nil! + (@page_size - 1)
        @last_index = current_index

        sliced_list = list[@start_index..@end_index.not_nil!]
        page_range = (@start_index..@end_index.not_nil!)

        sliced_list.each_with_index do |item, index|
          block.call(item, @start_index.not_nil! + index)
        end
      end

      # Paginate collection given an active index
      def paginate(list, active, page_size = nil)
        list = [] of Tuple(Choice, Int32)
        paginate { |e, i| list << {e, i} }
        list
      end
    end
  end
end
