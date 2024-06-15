require "term-cursor"
require "term-reader"
require "cor"

require "./prompt/*"

module Term
  class Prompt
    # Raised when wrong parameter is used to configure prompt
    class ConfigurationError < Exception; end

    # Raised when type conversion cannot be performed
    class ConversionError < Exception; end

    # Raised when the passed in validation argument is of wrong type
    class ValidationCoercion < Exception; end

    # Raised when the required argument is not supplied
    class ArgumentRequired < ArgumentError; end

    # Raised when the argument validation fails
    class ArgumentValidation < ArgumentError; end

    # Raised when the argument is not expected
    class InvalidArgument < ArgumentError; end

    property input : IO::FileDescriptor
    property output : IO::FileDescriptor
    property env : Hash(String, String)
    property prefix : String
    property palette : Palette
    property interrupt : Symbol
    property track_history : Bool

    getter cursor : Term::Cursor.class
    getter reader : Term::Reader
    getter symbols : Hash(Symbol, String)

    delegate :clear_lines, :clear_line, :show, :hide, to: @cursor
    delegate :read_char, :read_keypress, :read_line,
             :read_multiline, :trigger,
             :count_screen_lines, to: @reader
    delegate :print, :puts, :flush, to: @output

    def initialize(**options)
      @input          = options[:input]? || STDIN
      @output         = options[:output]? || STDOUT
      @env            = options[:env]? || ENV.to_h
      @prefix         = options[:prefix]? || ""
      @palette        = options[:palette]? || Palette.new
      @interrupt      = options[:interrupt]? || :error
      @track_history  = options[:track_history]? || true
      @symbols        = Symbols.symbols.merge(options[:symbols]? || {} of Symbol => String)

      @cursor = Term::Cursor
      @reader = Term::Reader.new(
        input: @input,
        output: @output,
        interrupt: @interrupt,
        track_history: @track_history,
        env: @env,
      )
    end

    # Change symbols used by this prompt
    def symbols(new_symbols = nil)
      return @symbols unless new_symbols
      @symbols.merge!(new_symbols)
    end

    # Ask a question.
    #
    # Example:
    # ```
    # prompt.ask("What is your name?")
    # ```
    def ask(message = "", **options, &block : Question ->)
      question = Question.new(self, **options)
      question.call(message, &block)
    end

    # ditto
    def ask(message = "", **options)
      ask(message, **options) { }
    end

    # Ask a question with a keypress answer.
    #
    # Example:
    # ```
    # prompt.keypress("Press any key to continue")
    # # or
    # prompt.keypress("Press Ctrl+D to continue", keys: [:ctrl_d])
    # ```
    def keypress(message = "", **options, &block : Keypress ->)
      question = Keypress.new(self, **options)
      question.call(message, &block)
    end

    # ditto
    def keypress(message = "", **options)
      keypress(message, **options) { }
    end

    # Ask a question with a multiline answer
    #
    # Example:
    # ```
    # prompt.multiline("Description?")
    # ```
    def multiline(message = "", **options, &block : Multiline ->)
      question = Multiline.new(self, **options)
      question.call(message, &block)
    end

    # ditto
    def multiline(message = "", **options)
      multiline(message, **options) { }
    end

    # Ask a masked question. Masked questions replace each input character
    # with a mask value.
    #
    # Example:
    # ```
    # prompt.mask("Please enter your password:")
    # ```
    def mask(message = "", **options, &block : MaskQuestion ->)
      question = MaskQuestion.new(self, **options)
      question.call(message, &block)
    end

    # ditto
    def mask(message = "", **options)
      mask(message, **options) { }
    end

    # Ask a yes or no question, with "yes" being the default answer.
    #
    # Example:
    # ```
    # prompt.yes?("Would you like to continue?")
    # ```
    def yes?(message = "", **options, &block : ConfirmQuestion ->)
      question = ConfirmQuestion.new(self, **options, default: true)
      question.call(message, &block)
    end

    # ditto
    def yes?(message = "", **options)
      yes?(message, **options) { }
    end

    # Ask a yes or no question, with "no" being the default answer.
    #
    # Example:
    # ```
    # prompt.no?("Would you like to continue?")
    # ```
    def no?(message = "", **options, &block : ConfirmQuestion ->)
      question = ConfirmQuestion.new(self, **options, default: false)
      question.call(message, &block)
    end

    # ditto
    def no?(message = "", **options)
      no?(message, **options) { }
    end

    # Gathers more than one answer
    #
    # Example:
    # ```
    # prompt.collect do
    #   key(:name).ask("Name?")
    #   key(:age).ask("Age?")
    # end
    # ```
    def collect(**options, &block : AnswersCollector ->)
      collector = AnswersCollector.new(self, **options)
      collector.call(&block)
    end

    # Expand available options
    #
    # Example:
    # ```
    # prompt = Term::Prompt.new
    #
    # choices = [{
    #   key: "Y",
    #   name: "Overwrite",
    #   value: :yes
    # }, {
    #   key: "n",
    #   name: "Skip",
    #   value: :no
    # }]
    #
    # prompt.expand("Overwrite shard.yml?", choices)
    # ```
    def expand(question, choices = nil, **options, &block : Expander ->)
      choices = choices.nil? ? [] of Choice : choices
      list = Expander.new(self, **options)
      list.call(question, choices, &block)
    end

    # ditto
    def expand(question, choices = nil, **options)
      expand(question, choices, **options) { }
    end

    # Ask a question with a range slider
    #
    # Example:
    # ```
    # prompt.slider("What size?", min: 32, max: 54, step: 2)
    # ```
    def slider(question, **options, &block : Slider ->)
      slider = Slider.new(self, **options)
      slider.call(question, &block)
    end

    # ditto
    def slider(question, **options)
      slider = Slider.new(self, **options)
      slider.call(question)
    end

    # Ask a question with indexed list
    #
    # Example:
    # ```
    # editors = %w(emacs nano vim)
    # prompt.enum_select("Select editor:", editors)
    # ```
    def enum_select(question, choices = nil, **options, &block : EnumList ->)
      choices = choices.nil? ? [] of Choice : choices
      list = EnumList.new(self, **options)
      list.call(question, choices, &block)
    end

    # ditto
    def enum_select(question, choices = nil, **options)
      enum_select(question, choices, **options) { }
    end

    # Ask a question with a list of options
    #
    # Example:
    # ```
    # prompt.select("What size?") do |menu|
    #   menu.choice :large
    #   menu.choices %w(:medium :small)
    # end
    # ```
    def select(question, choices = nil, **options, &block : List ->)
      choices = choices.nil? ? [] of Choice : choices
      list = List.new(self, **options)
      list.call(question, choices, &block)
    end

    # Ask a question with a list of options
    #
    # Example:
    # ```
    # prompt.select("What size?", %w(large medium small))
    # ```
    def select(question, choices = nil, **options)
      self.select(question, choices, **options) { }
    end

    # Ask a question with multiple attributes activated
    #
    # Example:
    # ```
    # prompt.multi_select("What sizes?") do |menu|
    #   menu.choice :large
    #   menu.choices %w(:medium :small)
    # end
    # ```
    def multi_select(question, choices = nil, **options, &block : List ->)
      choices = choices.nil? ? [] of Choice : choices
      list = MultiList.new(self, **options)
      list.call(question, choices, &block)
    end

    # Ask a question with multiple attributes activated
    #
    # Example:
    # ```
    # choices = %w(Scorpion Jax Kitana Baraka Jade)
    # prompt.multi_select("Choose your destiny?", choices)
    # ```
    def multi_select(question, choices = nil, **options)
      self.multi_select(question, choices, **options) { }
    end

    # Print statement(s) out using the palette active color.
    def ok(*args, **options)
      args.each { |message| say(message, color: @palette.active) }
    end

    # Print statement(s) out using the palette warning color.
    def warn(*args, **options)
      args.each { |message| say(message, color: @palette.warning) }
    end

    # Print statement(s) out using the palette error color.
    def error(*args, **options)
      args.each { |message| say(message, color: @palette.error) }
    end

    # Print statement out. If the supplied message ends with a space or
    # tab character, a new line will not be appended.
    #
    # Example
    # ```
    # prompt.say("Simple things.", color: :red)
    # ```
    def say(message = "", **options)
      message = message.to_s
      return if message.empty?

      statement = Statement.new(self, **options)
      statement.call(message)
    end

    # Print debug information in terminal top right corner.
    def debug(*messages)
      messages = messages.map(&.inspect)
      longest = messages.max_by(&.size).size
      width = Term::Screen.width - longest
      print cursor.save
      messages.reverse_each.with_index do |msg, i|
        print cursor.column(width) + cursor.up + cursor.clear_line_after
        print msg
      end
    ensure
      print cursor.restore
    end

    # Decorare the provided `message` using the given `color`. Color can be
    # a symbol, a `Cor` instance, or an `{R, G, B}` tuple.
    def decorate(message, color = @enabled_color)
      Cor.truecolor_string(message, fore: color)
    end
  end
end
