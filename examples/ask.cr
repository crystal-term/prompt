require "../src/term-prompt"

prompt = Term::Prompt.new

prompt.ask("What is your name?", default: ENV["USER"])
