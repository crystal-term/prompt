require "./spec_helper"

describe Term::Prompt::Slider do
  it "confirms the active range value on enter" do
    slider = Term::Prompt::Slider.new(term_prompt, min: 0, max: 10, step: 5)
    slider.spec_setup_defaults

    slider.keyright
    slider.keyenter

    slider.spec_done.should be_true
    slider.spec_answer.should eq(10)
  end

  it "uses an explicit default when it falls inside the range" do
    slider = Term::Prompt::Slider.new(term_prompt, min: 0, max: 10, step: 2, default: 4)
    slider.spec_setup_defaults

    slider.spec_active.should eq(2)
    slider.spec_answer.should eq(4)
  end

  it "falls back to the last value when the default is outside the stepped range" do
    slider = Term::Prompt::Slider.new(term_prompt, min: 0, max: 10, step: 3, default: 4)
    slider.spec_setup_defaults

    slider.spec_answer.should eq(9)
  end

  it "clamps arrow navigation at the range boundaries" do
    slider = Term::Prompt::Slider.new(term_prompt, min: 1, max: 3)
    slider.spec_setup_defaults

    slider.keyleft
    slider.keyleft
    slider.spec_answer.should eq(1)

    slider.keyright
    slider.keyright
    slider.keyright
    slider.spec_answer.should eq(3)
  end
end
