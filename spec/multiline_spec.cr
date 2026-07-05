require "./spec_helper"

class ScriptedMultiline < Term::Prompt::Multiline
  def initialize(prompt, @lines : Array(String), **options)
    super(prompt, **options)
  end

  def read_input
    @lines
  end
end

describe Term::Prompt::Multiline do
  it "returns joined lines from the reader" do
    question = ScriptedMultiline.new(term_prompt, ["one\n", "two\n"])

    question.call("Body?").should eq("one\ntwo\n")
  end

  it "returns the default when no multiline input is provided" do
    question = ScriptedMultiline.new(term_prompt, [] of String, default: "draft")

    question.call("Body?").should eq("draft")
    question.spec_input.should eq("draft")
  end

  it "increments the line count when enter is pressed" do
    question = Term::Prompt::Multiline.new(term_prompt)

    question.keyenter
    question.keyreturn

    question.spec_lines_count.should eq(2)
  end

  it "treats an empty reader result like ctrl-d termination with an empty answer" do
    question = ScriptedMultiline.new(term_prompt, [] of String)

    question.call("Body?").should eq("")
  end
end
