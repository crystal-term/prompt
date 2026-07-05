require "./spec_helper"

describe Term::Prompt::EnumList do
  it "confirms the typed numeric choice on enter" do
    list = Term::Prompt::EnumList.new(term_prompt)
    list.choices = %w(emacs nano vim)
    list.setup_defaults

    list.keypress("3", key_event("3"))
    list.keyenter

    list.done.should be_true
    list.answer.should eq("vim")
  end

  it "defaults to the first choice when no default is provided" do
    list = Term::Prompt::EnumList.new(term_prompt)
    list.choices = %w(emacs nano vim)

    list.setup_defaults

    list.default.should eq(1)
    list.spec_active.should eq(1)
    list.spec_page_active.should eq(1)
  end

  it "defaults to the first non-disabled choice when no default is provided" do
    list = Term::Prompt::EnumList.new(term_prompt)
    list.choices = [
      {name: "emacs", value: "emacs", disabled: "unavailable"},
      "nano",
      "vim",
    ]

    list.setup_defaults

    list.default.should eq(2)
    list.spec_active.should eq(2)
    list.answer.should eq("nano")
  end

  it "moves the visible page with right and left keys" do
    list = Term::Prompt::EnumList.new(term_prompt, page_size: 2)
    list.choices = %w(a b c d e)
    list.setup_defaults

    list.keyright
    list.spec_page_active.should eq(3)

    list.keyleft
    list.spec_page_active.should eq(1)
  end

  it "rejects out-of-range numeric input without raising" do
    list = Term::Prompt::EnumList.new(term_prompt)
    list.choices = %w(emacs nano vim)
    list.setup_defaults

    list.keypress("9", key_event("9"))
    list.keyenter

    list.done.should be_false
    list.failure.should be_true
  end

  it "does not treat zero as the last choice" do
    list = Term::Prompt::EnumList.new(term_prompt)
    list.choices = %w(emacs nano vim)
    list.setup_defaults

    list.keypress("0", key_event("0"))
    list.keyenter

    list.done.should be_false
    list.failure.should be_true
  end

  it "adds a computed choice with a block" do
    list = Term::Prompt::EnumList.new(term_prompt)
    list.choice("current shell") { "zsh" }
    list.setup_defaults

    list.keypress("1", key_event("1"))
    list.keyenter

    list.done.should be_true
    list.answer.should eq("zsh")
  end
end
