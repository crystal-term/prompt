module Term
  class Prompt
    # A class representing a statement output to prompt.
    struct Statement
      # Flag to display newline
      getter newline : Bool

      # Color used to display statement
      getter color : Term::Color?

      # Initialize a Statement
      def initialize(@prompt : Prompt, @newline = true, color = nil)
        if color
          @color = color.is_a?(Term::Color) ? color : Term::Color.color(color)
        end
      end

      # Output the message to the prompt
      def call(message)
        message = @prompt.decorate(message, @color.not_nil!) if @color

        if @newline && /( |\t)(\e\[\d+(;\d+)*m)?\Z/ !~ message
          @prompt.puts message
        else
          @prompt.print message
          @prompt.flush
        end
      end
    end
  end
end
