require "./paginator"

module Term
  class Prompt
    class BlockPaginator < Paginator
      # Paginate list of choices based on current active choice.
      # Move entire pages.
      def paginate(list, active, page_size = nil, &block : Choice, Int32 ->)
        default_size = (list.size <= DEFAULT_PAGE_SIZE ? list.size : DEFAULT_PAGE_SIZE)
        @page_size = page_size || @page_size || default_size

        check_page_size!

        # Don't paginate short lists
        if list.size <= @page_size
          @start_index = 0
          @end_index = list.size - 1
          return list.each_with_index(&block)
        end

        unless active.nil? # User may input index out of range
          @last_index = active
        end
        page  = (@last_index / @page_size).ceil.to_i
        pages = (list.size / @page_size).ceil.to_i
        if page == 0
          @start_index = 0
          @end_index = @start_index.not_nil! + @page_size - 1
        elsif page > 0 && page < pages
          @start_index = (page - 1) * @page_size
          @end_index = @start_index.not_nil! + @page_size - 1
        elsif page == pages
          @start_index = (page - 1) * @page_size
          @end_index = list.size - 1
        else
          @end_index = list.size - 1
          @start_index = @end_index.not_nil! - @page_size + 1
        end

        sliced_list = list[@start_index..@end_index]
        page_range = (@start_index..@end_index)

        sliced_list.each_with_index do |item, index|
          block.call(item, @start_index.not_nil! + index)
        end
      end
    end
  end
end
