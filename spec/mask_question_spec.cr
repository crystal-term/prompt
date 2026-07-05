require "./spec_helper"

describe Term::Prompt::MaskQuestion do
  it "captures typed input and marks the masked read done on enter" do
    question = Term::Prompt::MaskQuestion.new(term_prompt)

    question.keypress("s", key_event("s"))
    question.keypress("3", key_event("3"))
    question.keyenter

    question.spec_input.should eq("s3")
    question.spec_done_masked.should be_true
  end

  it "uses a custom mask character in rendered output" do
    question = Term::Prompt::MaskQuestion.new(term_prompt, "#")
    question.keypress("s", key_event("s"))
    question.keypress("3", key_event("3"))

    rendered = plain(question.render_question)

    rendered.should contain("##")
    rendered.should_not contain("s3")
  end

  it "removes the last character on backspace" do
    question = Term::Prompt::MaskQuestion.new(term_prompt)
    question.keypress("s", key_event("s"))
    question.keypress("3", key_event("3"))

    question.keypress("backspace", key_event("\b", "backspace"))

    question.spec_input.should eq("s")
  end
end
