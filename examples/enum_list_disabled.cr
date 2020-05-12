require "../src/term-prompt"

prompt = Term::Prompt.new

choices = [
  {name: "Emacs", disabled: "(not installed)"},
  "Atom",
  "GNU nano",
  {name: "Notepad++", disabled: "(not installed)"},
  "Sublime",
  "Vim"
]

prompt.enum_list("Select an editor", choices, default: 2)
