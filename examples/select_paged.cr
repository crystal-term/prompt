require "../src/term-prompt"

prompt = Term::Prompt.new
alphabet = ("A".."Z").to_a
answer = prompt.select("Which letter?", alphabet, per_page: 7, cycle: true, default: 5)
puts answer
