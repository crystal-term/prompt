require "./spec_helper"

class ScriptedQuestion < Term::Prompt::Question
  getter reads : Int32

  def initialize(prompt, @answers : Array(String), **options)
    super(prompt, **options)
    @reads = 0
  end

  def read_input(question)
    answer = @answers[@reads]? || ""
    @reads += 1
    answer
  end
end

describe Term::Prompt::Question do
  it "re-asks required questions after an empty answer" do
    question = ScriptedQuestion.new(term_prompt, ["", "Ada"], required: true)

    question.call("Name?").should eq("Ada")

    question.reads.should eq(2)
    question.spec_done.should be_true
  end

  it "records validator rejection messages on failure" do
    validator = Proc(Term::Prompt::Question, String?, Bool).new do |question, value|
      if value == "ok"
        true
      else
        question.errors << "Value must be ok"
        false
      end
    end
    question = ScriptedQuestion.new(term_prompt, ["bad"], validators: [validator])

    result = question.process_input(question.spec_render_question)

    result.failure?.should be_true
    question.errors.should eq(["Value must be ok"])
  end

  it "returns the default when input is empty" do
    question = ScriptedQuestion.new(term_prompt, [""], default: "guest")

    question.call("Name?").should eq("guest")

    question.spec_input.should eq("guest")
  end

  it "leaves non-empty input unchanged without a converter" do
    question = ScriptedQuestion.new(term_prompt, ["42"])

    question.call("Age?").should eq("42")
  end

  pending "source gap: convert: :int should return an Int32 value" do
    question = ScriptedQuestion.new(term_prompt, ["42"], convert: :int)

    question.call("Age?").should eq(42)
  end
end
