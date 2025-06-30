require "../src/term-prompt"

prompt = Term::Prompt.new

# Multi-select with minimum requirement
# User must select at least 2 drinks before they can submit
drinks = ["vodka", "beer", "wine", "whisky", "bourbon"]
answer = prompt.multi_select("Choose at least 2 drinks:", drinks, min: 2)

puts "You selected: #{answer.join(", ")}"
