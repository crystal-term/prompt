require "./spec_helper"

describe Term::Prompt::Autocomplete do
  it "confirms the active suggestion on enter" do
    autocomplete = Term::Prompt::Autocomplete.new(term_prompt)
    autocomplete.choices %w(Rails React Vue)

    autocomplete.keypress("r", key_event("r"))
    autocomplete.keypress("e", key_event("e"))
    autocomplete.keyenter

    autocomplete.spec_done.should be_true
    autocomplete.spec_answer.should eq("React")
  end

  it "returns an explicit default when there are no suggestions and no input" do
    autocomplete = Term::Prompt::Autocomplete.new(term_prompt, default: "Rails")
    autocomplete.choices([] of String)

    autocomplete.keyenter

    autocomplete.spec_done.should be_true
    autocomplete.spec_answer.should eq("Rails")
  end

  it "allows custom input when the filter has zero matches" do
    autocomplete = Term::Prompt::Autocomplete.new(term_prompt)
    autocomplete.choices %w(Rails React Vue)

    autocomplete.keypress("z", key_event("z"))

    autocomplete.spec_suggestion_names.should eq([] of String)
    plain(autocomplete.spec_render_question).should contain("No matches found")

    autocomplete.keyenter
    autocomplete.spec_done.should be_true
    autocomplete.spec_answer.should eq("z")
  end

  it "cycles through suggestions when configured to cycle" do
    autocomplete = Term::Prompt::Autocomplete.new(term_prompt, cycle: true)
    autocomplete.choices %w(Rails React Vue)

    autocomplete.keyup
    autocomplete.spec_active.should eq(3)

    autocomplete.keydown
    autocomplete.spec_active.should eq(1)
  end
end
