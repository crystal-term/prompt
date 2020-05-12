require "../src/term-prompt"

prompt = Term::Prompt.new

prompt.ask("What\nis\nyour\nname?", default: ENV["USER"])
