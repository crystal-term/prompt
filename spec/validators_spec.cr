require "./spec_helper"

private alias RequiredValidator = Term::Prompt::Question::Validators::RequiredValidator
private alias LengthValidator = Term::Prompt::Question::Validators::LengthValidator
private alias PatternValidator = Term::Prompt::Question::Validators::PatternValidator

describe Term::Prompt::Question::Validators::RequiredValidator do
  it "accepts non-empty values" do
    question = Term::Prompt::Question.new(term_prompt)

    RequiredValidator.new.call(question, "Ada").should be_true
    question.errors.should be_empty
  end

  it "rejects empty values when no default is available" do
    question = Term::Prompt::Question.new(term_prompt)

    RequiredValidator.new.call(question, "").should be_false
    question.errors.should eq(["Value is required"])
  end

  it "accepts empty values when a default is available" do
    question = Term::Prompt::Question.new(term_prompt, default: "Ada")

    RequiredValidator.new.call(question, "").should be_true
    question.errors.should be_empty
  end
end

describe Term::Prompt::Question::Validators::LengthValidator do
  it "accepts values inside the configured length range" do
    question = Term::Prompt::Question.new(term_prompt)

    LengthValidator.new(2, 4).call(question, "Ada").should be_true
    question.errors.should be_empty
  end

  it "rejects values shorter than the minimum" do
    question = Term::Prompt::Question.new(term_prompt)

    LengthValidator.new(3, nil).call(question, "Al").should be_false
    question.errors.should eq(["Too short. Must be at least 3 characters long."])
  end

  it "rejects values longer than the maximum" do
    question = Term::Prompt::Question.new(term_prompt)

    LengthValidator.new(nil, 3).call(question, "Grace").should be_false
    question.errors.should eq(["Too long. Must be at most 3 characters long."])
  end
end

describe Term::Prompt::Question::Validators::PatternValidator do
  it "accepts values matching the pattern" do
    question = Term::Prompt::Question.new(term_prompt)

    PatternValidator.new(/\A\d{5}\z/).call(question, "12345").should be_true
    question.errors.should be_empty
  end

  it "rejects values that do not match the pattern" do
    question = Term::Prompt::Question.new(term_prompt)

    PatternValidator.new(/\A\d{5}\z/).call(question, "abc").should be_false
    question.errors.should eq(["Must match pattern \\A\\d{5}\\z"])
  end
end
