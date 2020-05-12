require "../src/term-prompt"

prompt = Term::Prompt.new
prompt.keypress("Press Ctrl+C to continue", keys: [:crtl_c])
