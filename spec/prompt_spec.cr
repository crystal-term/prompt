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

      question.convert_result("y").should be_true
      question.convert_result("Yes").should be_true
      question.convert_result("n").should be_false
      question.convert_result("okay").should be_false
    end

    it "uses custom positive and negative labels" do
      question = Term::Prompt::ConfirmQuestion.new(Term::Prompt.new, true, nil, "ja", "nein")
      question.setup_defaults

      question.positive.should eq("ja")
      question.negative.should eq("nein")
      question.convert_result("ja").should be_true
      question.convert_result("nein").should be_false
    end
  end

  it "passes explicit track_history false to the reader" do
    prompt = Term::Prompt.new(track_history: false)

    prompt.track_history.should be_false
    prompt.reader.track_history?.should be_false
    Term::Prompt.new.reader.track_history?.should be_true
  end
end
