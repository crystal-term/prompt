module Term
  class Prompt
    class Question
      module Validators
        class RequiredValidator < Validator
          def call(question : Question, value : String?) : Bool
            if value.to_s.strip.empty? && !question.default?
              question.errors << "Value is required"
              false
            else
              true
            end
          end
        end

        class LengthValidator < Validator
          property min : Int32?

          property max : Int32?

          def initialize(@min : Int32?, @max : Int32?)
          end

          def call(question : Question, value : String?) : Bool
            result = true

            if (min = @min) && (value.to_s.size < min)
              question.errors << "Too short. Must be at least #{min} characters long."
              result = false
            end

            if (max = @max) && (value.to_s.size > max)
              question.errors << "Too long. Must be at most #{max} characters long."
              result = false
            end

            result
          end
        end

        class PatternValidator < Validator
          property pattern : Regex

          def initialize(@pattern : Regex)
          end

          def call(question : Question, value : String?) : Bool
            unless value.to_s.match(pattern)
              question.errors << "Must match pattern #{pattern.source}"
              return false
            end
            true
          end
        end
      end
    end
  end
end
