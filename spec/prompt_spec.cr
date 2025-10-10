require "./spec_helper"

describe Term::Prompt do

  it "has a version Number" do
    Term::Prompt::VERSION.should match(/\d+\.\d+\.\d+/)
  end
end
