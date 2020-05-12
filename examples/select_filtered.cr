require "../src/term-prompt"

prompt = Term::Prompt.new

warriors = ["Scorpion", "Kano", "Jax", "Kitana", "Raiden"]

answer = prompt.select("Choose your destiny?", warriors, filter: true)

puts answer
