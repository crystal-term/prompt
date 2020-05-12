require "../src/term-prompt"

prompt = Term::Prompt.new
prompt.slider("Volume", max: 100, step: 5, default: 75, format: "|:slider| %d%%")
