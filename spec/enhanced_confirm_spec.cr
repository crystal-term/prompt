require "./spec_helper"

describe Term::Prompt::EnhancedConfirm do
  it "confirms a simple yes response" do
    confirm = Term::Prompt::EnhancedConfirm.new(term_prompt)

    confirm.keypress("y", key_event("y"))
    confirm.keyenter

    confirm.spec_done.should be_true
    confirm.result.should be_true
  end

  it "treats a simple no response as cancelled" do
    confirm = Term::Prompt::EnhancedConfirm.new(term_prompt)

    confirm.keypress("n", key_event("n"))
    confirm.keyenter

    confirm.spec_done.should be_true
    confirm.result.should be_false
  end

  it "clears incorrect exact confirmation input without finishing" do
    confirm = Term::Prompt::EnhancedConfirm.new(term_prompt, destructive: true)

    confirm.keypress("n", key_event("n"))
    confirm.keypress("o", key_event("o"))
    confirm.keyenter

    confirm.spec_done.should be_false
    confirm.spec_input.should eq("")
  end

  it "requires two confirmations when double_confirm is enabled" do
    confirm = Term::Prompt::EnhancedConfirm.new(term_prompt, double_confirm: true)

    "yes".each_char { |char| confirm.keypress(char.to_s, key_event(char.to_s)) }
    confirm.keyenter

    confirm.spec_done.should be_false
    confirm.spec_confirmations.should eq(["yes"])

    "yes".each_char { |char| confirm.keypress(char.to_s, key_event(char.to_s)) }
    confirm.keyenter

    confirm.spec_done.should be_true
    confirm.result.should be_true
  end
end
