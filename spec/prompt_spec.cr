require "./spec_helper"

describe Term::Prompt do
  after_each do
    Term::Color.enabled = nil
  end

  it "has a version Number" do
    Term::Prompt::VERSION.should match(/\d+\.\d+\.\d+/)
  end

  describe "#decorate" do
    it "returns plain text when term color is disabled" do
      Term::Color.enabled = false

      Term::Prompt.new.decorate("hi", :red).should eq("hi")
    end
  end

  describe Term::Prompt::ConfirmQuestion do
    it "converts the positive shortcut without relying on Char escaping" do
      question = Term::Prompt::ConfirmQuestion.new(Term::Prompt.new, true)
      question.setup_defaults

      question.convert_result("Y").should be_true
      question.convert_result("n").should be_false
    end

    pending "fixed by plan 008" do
      question = Term::Prompt::ConfirmQuestion.new(Term::Prompt.new, true, "Y/n", "Proceed", "Cancel")
      question.setup_defaults

      question.positive.should eq("Proceed")
      question.negative.should eq("Cancel")
    end
  end

  pending "fixed by plan 008" do
    Term::Prompt.new(track_history: false).track_history.should be_false
  end
end
