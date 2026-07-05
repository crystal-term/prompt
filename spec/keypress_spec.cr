require "./spec_helper"

describe Term::Prompt::Keypress do
  it "finishes on any key when no key list is configured" do
    question = Term::Prompt::Keypress.new(term_prompt)

    question.keypress("x", key_event("x"))

    question.spec_done.should be_true
  end

  it "finishes only for configured key names" do
    question = Term::Prompt::Keypress.new(term_prompt, keys: ["ctrl_d"])

    question.keypress("x", key_event("x"))
    question.spec_done.should be_false

    question.keypress("ctrl_d", key_event("\u0004", "ctrl_d"))
    question.spec_done.should be_true
  end

  it "starts with echo disabled by default" do
    question = Term::Prompt::Keypress.new(term_prompt)

    question.echo?.should be_false
  end
end
