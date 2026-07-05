require "./spec_helper"

describe Term::Prompt::Expander do
  it "confirms the choice matching the typed key" do
    expander = Term::Prompt::Expander.new(term_prompt)
    expander.choice("Overwrite", "overwrite", "o")
    expander.choice("Skip", "skip", "s")
    expander.spec_setup_defaults

    expander.keypress("o", key_event("o"))
    expander.keyenter

    expander.done.should be_true
    expander.selected.try(&.name).should eq("Overwrite")
    expander.spec_answer.should eq("overwrite")
  end

  it "uses the default choice when enter is pressed with no input" do
    expander = Term::Prompt::Expander.new(term_prompt, default: 2)
    expander.choice("Overwrite", "overwrite", "o")
    expander.choice("Skip", "skip", "s")
    expander.spec_setup_defaults

    expander.keyenter

    expander.done.should be_true
    expander.default_key.should be_true
    expander.spec_answer.should eq("skip")
  end

  it "expands help without completing the prompt" do
    expander = Term::Prompt::Expander.new(term_prompt)
    expander.choice("Overwrite", "overwrite", "o")
    expander.choice(**Term::Prompt::Expander::HELP_CHOICE)
    expander.spec_setup_defaults

    expander.keypress("h", key_event("h"))
    expander.keyenter

    expander.expanded?.should be_true
    expander.done.should be_false
    expander.selected.should be_nil
  end

  it "updates the hint for a matching key while collapsed" do
    expander = Term::Prompt::Expander.new(term_prompt)
    expander.choice("Overwrite", "overwrite", "o")
    expander.spec_setup_defaults

    expander.keypress("o", key_event("o"))

    expander.hint.should eq("Overwrite")
  end

  pending "fixed by plan 008: Expander#choices getter should return configured choices"
end
