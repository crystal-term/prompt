require "./question"

module Term
  class Prompt
    class ConfirmQuestion < Question
      getter? suffix : String?
      property suffix : String?

      getter? positive : String?
      property positive : String?

      getter? negative : String?
      property negative : String?

      @_default : Bool

      def initialize(prompt, default = nil, suffix = nil, positive = nil, negative = nil, **options)
        super(prompt, **options)
        @suffix = suffix
        @positive = suffix
        @negative = suffix
        @_default = default || false
      end

      def default?
        !!@_default
      end

      def default
        @_default
      end

      def call(message = nil, &block : ConfirmQuestion ->)
        return if message.nil?
        @question = message.not_nil!
        block.call(self)
        setup_defaults
        render
      end

      def call(message)
        call(message) { }
      end

      def render_question
        String.build do |str|
          str << "#{@prefix}#{@question} "
          if !@done
            str << @prompt.decorate("(#{@suffix})", @palette.help) + ' '
          else
            answer = convert_result(@input)
            label  = answer ? @positive : @negative
            str << @prompt.decorate(label.to_s, @palette.active)
          end
          str << "\n" if @done
        end
      end

      def process_input(question)
        @input = read_input(question)
        if @input.to_s.strip.empty?
          @input = default? ? positive : negative
        end
        Result.new(self, @input).process
      end

      def setup_defaults
        return if suffix? && positive?

        if (suffix = @suffix) && (!positive? || !negative?)
          parts = suffix.split("/")
          @positive = parts[0]
          @negative = parts[1]
        elsif !suffix? && positive?
          @suffix = create_suffix
        else
          create_default_labels
        end
      end

      def create_default_labels
        @suffix   = default ? "Y/n" : "y/N"
        @positive = default ? "Yes" : "yes"
        @negative = default ? "no" : "No"
        @validators << PatternValidator.new(/^(y(es)?|no?)$/i)
      end

      def create_suffix
        (default ? positive.not_nil!.capitalize : positive.not_nil!.downcase) + "/" +
          (default ? negative.not_nil!.downcase : negative.not_nil!.capitalize)
      end

      def convert_result(value)
        positive_word   = Regex.escape(positive.to_s)
        positive_letter = Regex.escape(positive.to_s[0])
        pattern = Regex.new("^#{positive_word}|#{positive_letter}$", Regex::Options::IGNORE_CASE)
        !value.to_s.match(pattern).nil?
      end
    end
  end
end
