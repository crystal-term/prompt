module Term
  class Prompt
    struct Choice
      # Create choice from value
      #
      # Example:
      # ```
      # Choice.from(:foo)
      # # => <Term::Prompt::Choice @key=nil @name="foo" @value="foo" @disabled=false>
      #
      # Choice.from({name: :foo, value: 1, key: 'f'}
      # # => <Term::Prompt::Choice @key="f" @name="foo" @value=1 @disabled=false>
      # ```
      def self.from(val)
        case val
        when Choice
          val
        when NamedTuple
          new(**val)
        else
          new(val, val)
        end
      end

      # The label name
      getter name : String

      # The keyboard key to activate this choice
      getter key : String?

      # The text to display for disabled choice
      getter disabled : String?

      @value : (String | Proc(String))?

      # Create a Choice instance
      def initialize(@name, @value = nil, @key = nil, @disabled = nil)
      end

      def disabled?
        !!@disabled
      end

      # Read value and evaluate
      def value
        value = @value
        case value
        when Proc
          value.call
        else
          value
        end
      end

      # Object equality comparison
      def ==(other)
        return false unless other.is_a?(Choice)
        name == other.name &&
        value == other.value &&
        key == other.key
      end

      # Object string representation
      def to_s
        @name.to_s
      end
    end
  end
end
