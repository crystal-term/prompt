require "../src/term-prompt"

prompt = Term::Prompt.new(prefix: ">")

answer = prompt.ask

puts "Answer: \"#{answer}\""
