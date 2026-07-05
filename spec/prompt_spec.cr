require "./spec_helper"

class Term::Prompt::List
  def spec_setup_defaults
    setup_defaults
  end

  def spec_active
    @active
  end

  def spec_done
    @done
  end

  def spec_visible_names
    choices.map(&.name)
  end

  def spec_render_menu
    render_menu
  end

  def spec_answer
    answer
  end
end

class Term::Prompt::EnumList
  def spec_active
    @active
  end

  def spec_page_active
    @page_active
  end
end

private def key_event(value)
  Term::Reader::KeyEvent.from({} of String => String, value)
end

describe Term::Prompt do
  it "has a version Number" do
    Term::Prompt::VERSION.should match(/\d+\.\d+\.\d+/)
  end

  describe Term::Prompt::ConfirmQuestion do
    it "converts the positive shortcut without relying on Char escaping" do
      question = Term::Prompt::ConfirmQuestion.new(Term::Prompt.new, true)
      question.setup_defaults

      question.convert_result("Y").should be_true
      question.convert_result("n").should be_false
    end
  end

  describe Term::Prompt::EnumList do
    it "defaults to the first choice when no default is provided" do
      list = Term::Prompt::EnumList.new(Term::Prompt.new)
      list.choices = %w(emacs nano vim)

      list.setup_defaults

      list.default.should eq(1)
      list.spec_active.should eq(1)
      list.spec_page_active.should eq(1)
    end

    it "defaults to the first non-disabled choice when no default is provided" do
      list = Term::Prompt::EnumList.new(Term::Prompt.new)
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
  end

  describe Term::Prompt::List do
    it "filters visible choices and keeps the active index on a match" do
      list = Term::Prompt::List.new(Term::Prompt.new, filter: true)
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
      list = Term::Prompt::List.new(Term::Prompt.new, filter: true)
      list.choices %w(Scorpion Kano Jax Kitana Raiden)
      list.spec_setup_defaults

      list.keypress("z", key_event("z"))

      list.spec_visible_names.should eq([] of String)
      list.spec_active.should eq(0)
      list.spec_render_menu.should contain("No matches")

      list.keyreturn
      list.spec_done.should be_false
    end

    it "restores a valid active selection when a no-match filter is shortened" do
      list = Term::Prompt::List.new(Term::Prompt.new, filter: true)
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
      list = Term::Prompt::List.new(Term::Prompt.new)
      list.choices %w(a b c)
      list.spec_setup_defaults

      Term::Reader.global_handlers["enter"].each &.call("enter", key_event("\r"))
      list.spec_done.should be_true
    end
  end

  describe Term::Prompt::MultiList do
    it "accepts array defaults for multiple selected choices" do
      list = Term::Prompt::MultiList.new(Term::Prompt.new)
      list.choices %w(Vodka Gin Rum Whisky)

      list.default = [1, 3]
      list.setup_defaults

      list.answer.should eq(["Vodka", "Rum"])
    end
  end
end
