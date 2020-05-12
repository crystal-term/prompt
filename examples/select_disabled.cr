require "../src/term-prompt"

prompt = Term::Prompt.new

warriors = [
  "Scorpion",
  "Kano",
  { name: "Goro", disabled: "(injury)" },
  "Jax",
  "Kitana",
  "Raiden"
]

answer = prompt.select("Choose your destiny?", warriors, separator: ")")

puts answer
