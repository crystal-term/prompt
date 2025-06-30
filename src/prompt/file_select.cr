require "file_utils"

module Term
  class Prompt
    # A class responsible for rendering file/directory selection prompt
    # Used by {Prompt} to display interactive file browser.
    #
    # @api private
    class FileSelect
      HELP = "(↑/↓ to navigate, Enter to select, ← to go up, → to enter directory)"

      property symbols : Hash(Symbol, String)
      setter help : String?

      @prompt : Prompt
      @prefix : String
      @question : String = ""
      @current_path : String
      @active : Int32
      @done : Bool
      @first_render : Bool
      @cycle : Bool
      @palette : Palette
      @show_hidden : Bool
      @filter_ext : Array(String)?
      @file_only : Bool
      @dir_only : Bool
      @result : String?

      def initialize(@prompt : Prompt, **options)
        @prefix = options[:prefix]? || @prompt.prefix
        @current_path = options[:start_path]?.try(&.to_s) || Dir.current
        @active = 1
        @done = false
        @first_render = true
        @cycle = options[:cycle]? || false
        @palette = options[:palette]? || @prompt.palette
        @symbols = @prompt.symbols.merge(options[:symbols]? || {} of Symbol => String)
        @help = options[:help]?
        @show_hidden = options[:show_hidden]? || false
        @filter_ext = options[:filter]?.try(&.as(Array(String)))
        @file_only = options[:file_only]? || false
        @dir_only = options[:dir_only]? || false
        @result = nil

        Term::Reader.subscribe(:return, :enter, :up, :down, :left, :right)
      end

      # Get current directory entries
      def entries
        return [] of {String, Symbol} unless Dir.exists?(@current_path)
        
        items = [] of {String, Symbol}
        
        # Add parent directory unless at root
        unless @current_path == "/"
          items << {"..", :directory}
        end

        begin
          Dir.entries(@current_path).each do |entry|
            next if entry == "." || entry == ".."
            next if !@show_hidden && entry.starts_with?(".")
            
            full_path = File.join(@current_path, entry)
            
            if Dir.exists?(full_path)
              next if @file_only
              items << {entry, :directory}
            elsif File.exists?(full_path)
              next if @dir_only
              
              # Filter by extension if specified
              if ext_filter = @filter_ext
                ext = File.extname(entry).downcase
                next unless ext_filter.includes?(ext)
              end
              
              items << {entry, :file}
            end
          end
        rescue ex : File::AccessDeniedError
          items << {"[Access Denied]", :error}
        end

        items.sort! do |a, b|
          # Directories first, then files, alphabetically within each group
          if a[1] == b[1]
            a[0].downcase <=> b[0].downcase
          else
            a[1] == :directory ? -1 : 1
          end
        end
        items
      end

      # Call the file select prompt
      def call(question, &block : FileSelect ->)
        @question = question
        yield self if block
        render
      end

      # Default help text
      def help
        @help || HELP
      end

      def keyup
        return if entries.empty?
        
        if @active > 1
          @active -= 1
        elsif @cycle
          @active = entries.size
        end
      end

      def keydown
        return if entries.empty?
        
        if @active < entries.size
          @active += 1
        elsif @cycle
          @active = 1
        end
      end

      def keyleft
        # Go up one directory
        return if @current_path == "/"
        
        @current_path = File.dirname(@current_path)
        @active = 1
      end

      def keyright
        return if entries.empty? || @active > entries.size
        
        entry_name, entry_type = entries[@active - 1]
        return unless entry_type == :directory
        
        if entry_name == ".."
          keyleft
        else
          new_path = File.join(@current_path, entry_name)
          if Dir.exists?(new_path)
            @current_path = new_path
            @active = 1
          end
        end
      end

      def keyenter
        return if entries.empty? || @active > entries.size
        
        entry_name, entry_type = entries[@active - 1]
        
        case entry_type
        when :directory
          if entry_name == ".."
            keyleft
          else
            new_path = File.join(@current_path, entry_name)
            if Dir.exists?(new_path)
              if @dir_only
                # Select directory
                @result = new_path
                @done = true
              else
                # Enter directory
                @current_path = new_path
                @active = 1
              end
            end
          end
        when :file
          unless @dir_only
            @result = File.join(@current_path, entry_name)
            @done = true
          end
        end
      end

      def keyreturn
        keyenter
      end

      # Render the file select prompt
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
        @result || @current_path
      end

      # Clear screen lines
      private def refresh(lines)
        @prompt.clear_lines(lines)
      end

      # Render the complete question with file list
      private def render_question
        String.build do |str|
          str << "#{@prefix}#{@question} #{render_header}\n"
          
          unless @done
            # Show current path
            str << @prompt.decorate("Path: #{@current_path}", @palette.help)
            str << "\n\n"
            
            # Show entries
            current_entries = entries
            if current_entries.empty?
              str << @prompt.decorate("  [Empty directory]", @palette.help)
            else
              current_entries.each_with_index do |(entry_name, entry_type), index|
                if index + 1 == @active
                  str << @prompt.decorate("  #{@symbols[:marker]} ", @palette.active)
                else
                  str << "    "
                end
                
                case entry_type
                when :directory
                  if entry_name == ".."
                    str << @prompt.decorate("📁 #{entry_name}", @palette.help)
                  else
                    str << @prompt.decorate("📁 #{entry_name}/", @palette.active)
                  end
                when :file
                  str << "📄 #{entry_name}"
                when :error
                  str << @prompt.decorate("❌ #{entry_name}", @palette.error)
                end
                
                str << "\n" unless index == current_entries.size - 1
              end
            end
          end
        end
      end

      # Render header with help
      private def render_header
        if @done
          if result = @result
            @prompt.decorate(File.basename(result), @palette.active)
          else
            ""
          end
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