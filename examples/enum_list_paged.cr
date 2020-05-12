require "../src/term-prompt"

prompt = Term::Prompt.new
alphabet = ("A".."Z").to_a
prompt.enum_list("Select an editor", alphabet, per_page: 4, cycle: true, default: 2)
