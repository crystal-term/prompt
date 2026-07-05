require "./spec_helper"

describe Term::Prompt::List do
  it "confirms the active choice on enter" do
    list = Term::Prompt::List.new(term_prompt)
    list.choices %w(small medium large)
    list.spec_setup_defaults

    list.keydown
    list.keyenter

    list.spec_done.should be_true
    list.spec_answer.should eq("medium")
  end

  it "uses an explicit default as the active choice" do
    list = Term::Prompt::List.new(term_prompt, default: 3)
    list.choices %w(small medium large)
    list.spec_setup_defaults

    list.spec_active.should eq(3)
    list.spec_answer.should eq("large")
  end

  it "cycles from the first choice to the last when configured" do
    list = Term::Prompt::List.new(term_prompt, cycle: true)
    list.choices %w(small medium large)
    list.spec_setup_defaults

    list.keyup

    list.spec_active.should eq(3)
  end

  it "filters visible choices and keeps the active index on a match" do
    list = Term::Prompt::List.new(term_prompt, filter: true)
    list.choices %w(Scorpion Kano Jax Kitana Raiden)
    list.spec_setup_defaults

    list.keypress("k", key_event("k"))
    list.spec_visible_names.should eq(["Kano", "Kitana"])
    list.spec_active.should eq(1)

    list.keypress("a", key_event("a"))
    list.spec_visible_names.should eq(["Kano"])
    list.spec_active.should eq(1)
  end

  it "handles no matches without allowing the active selection to be submitted" do
    list = Term::Prompt::List.new(term_prompt, filter: true)
    list.choices %w(Scorpion Kano Jax Kitana Raiden)
    list.spec_setup_defaults

    list.keypress("z", key_event("z"))

    list.spec_visible_names.should eq([] of String)
    list.spec_active.should eq(0)
    plain(list.spec_render_menu).should contain("No matches")

    list.keyreturn
    list.spec_done.should be_false
  end

  it "restores a valid active selection when a no-match filter is shortened" do
    list = Term::Prompt::List.new(term_prompt, filter: true)
    list.choices %w(Scorpion Kano Jax Kitana Raiden)
    list.spec_setup_defaults

    list.keypress("k", key_event("k"))
    list.keypress("a", key_event("a"))
    list.keypress("z", key_event("z"))
    list.keybackspace

    list.spec_visible_names.should eq(["Kano"])
    list.spec_active.should eq(1)

    list.keyreturn
    list.spec_done.should be_true
    list.spec_answer.should eq("Kano")
  end

  it "marks the list done when the enter key event fires" do
    prompt = term_prompt
    list = Term::Prompt::List.new(prompt)
    list.choices %w(a b c)
    list.spec_setup_defaults
    list.spec_register_subscriptions

    prompt.reader.component_handlers["enter"].each &.call("enter", key_event("\r"))
    list.spec_done.should be_true
  end

  it "scopes key handlers to the most recently registered list" do
    prompt = term_prompt
    first = Term::Prompt::List.new(prompt)
    first.choices %w(a b c)
    first.spec_setup_defaults

    second = Term::Prompt::List.new(prompt)
    second.choices %w(one two three)
    second.spec_setup_defaults

    first.spec_register_subscriptions
    second.spec_register_subscriptions
    prompt.reader.component_handlers["down"].each &.call("down", key_event("\e[B", "down"))

    first.spec_active.should eq(1)
    second.spec_active.should eq(2)
  end
end

describe Term::Prompt::MultiList do
  it "accepts array defaults for multiple selected choices" do
    list = Term::Prompt::MultiList.new(term_prompt)
    list.choices %w(Vodka Gin Rum Whisky)

    list.default = [1, 3]
    list.setup_defaults

    list.answer.should eq(["Vodka", "Rum"])
  end

  it "toggles the active choice with space and finishes on enter" do
    list = Term::Prompt::MultiList.new(term_prompt)
    list.choices %w(Vodka Gin Rum)
    list.setup_defaults

    list.keyspace
    list.keydown
    list.keyspace
    list.keyenter

    list.spec_done.should be_true
    list.answer.should eq(["Vodka", "Gin"])
  end
end
