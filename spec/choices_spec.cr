require "./spec_helper"

describe Term::Prompt::Choice do
  it "converts strings into choices with matching names and values" do
    choice = Term::Prompt::Choice.from("small")

    choice.name.should eq("small")
    choice.value.should eq("small")
  end

  it "converts named tuples including disabled messages" do
    choice = Term::Prompt::Choice.from({name: "large", value: "l", disabled: "sold out"})

    choice.name.should eq("large")
    choice.value.should eq("l")
    choice.disabled?.should be_true
    choice.disabled.should eq("sold out")
  end

  it "returns choice instances unchanged" do
    choice = Term::Prompt::Choice.new("large", "l")

    Term::Prompt::Choice.from(choice).should eq(choice)
  end
end

describe Term::Prompt::Choices do
  it "delegates indexed access to the stored choices" do
    choices = Term::Prompt::Choices["small", "large"]

    choices[0].name.should eq("small")
    choices[1].value.should eq("large")
  end
end
