require "../src/term-prompt"

prompt = Term::Prompt.new
bullet = prompt.decorate(prompt.symbols[:bullet] + " ", :magenta)

res = prompt.mask("What is your secret? ", mask: bullet)

puts "Secret: \"#{res}\""
