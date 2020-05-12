require "../src/term-prompt"

prompt = Term::Prompt.new
drinks = ["vodka", "beer", "wine", "whisky", "bourbon"]
answer = prompt.multi_select("Choose your favourite drink", drinks)
puts answer
