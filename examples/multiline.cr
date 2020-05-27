require "../src/term-prompt"

prompt = Term::Prompt.new

answer = prompt.multiline("Description:")

puts answer
