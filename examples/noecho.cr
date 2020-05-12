require "../src/term-prompt"

prompt = Term::Prompt.new

password = prompt.ask("Password?", echo: false)

puts "Password: #{password}"
