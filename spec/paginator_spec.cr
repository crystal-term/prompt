require "./spec_helper"

private def page_names(paginator, choices, active, page_size)
  names = [] of String
  paginator.paginate(choices, active, page_size) do |choice, _index|
    names << choice.name
  end
  names
end

describe Term::Prompt::Paginator do
  it "windows the first page around the active item" do
    choices = Term::Prompt::Choices["a", "b", "c", "d", "e", "f", "g"]

    page_names(Term::Prompt::Paginator.new, choices, 1, 3).should eq(%w(a b c))
  end

  it "windows a middle page around the active item" do
    choices = Term::Prompt::Choices["a", "b", "c", "d", "e", "f", "g"]

    page_names(Term::Prompt::Paginator.new, choices, 5, 3).should eq(%w(d e f))
  end

  it "windows the last page around the active item" do
    choices = Term::Prompt::Choices["a", "b", "c", "d", "e", "f", "g"]

    page_names(Term::Prompt::Paginator.new, choices, 7, 3).should eq(%w(e f g))
  end

  pending "fixed by plan 008: blockless Paginator#paginate should return choice-index tuples"
end

describe Term::Prompt::BlockPaginator do
  it "moves by whole pages in the block overload" do
    choices = Term::Prompt::Choices["a", "b", "c", "d", "e", "f", "g"]

    page_names(Term::Prompt::BlockPaginator.new, choices, 5, 3).should eq(%w(d e f))
  end
end
