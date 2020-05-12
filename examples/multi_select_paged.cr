require "../src/term-prompt"

prompt = Term::Prompt.new
alphabet = ("A".."Z").to_a
answer = prompt.multi_select("Which letters?", alphabet, per_page: 7, max: 3)
puts answer
