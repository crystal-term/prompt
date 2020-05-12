module Term
  class Prompt
    alias ValidatorProc = Proc(Question, String?, Bool)
    abstract class Validator
      abstract def call(question : Question, value : String?) : Bool
    end
  end
end
