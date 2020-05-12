require "../src/term-prompt"

prompt = Term::Prompt.new
choices = ["/bin/nano", "/usr/bin/vim.basic", "/usr/bin/vim.tiny", "/usr/bin/emacs"]
prompt.enum_select("Select an editor", choices, default: 2)
