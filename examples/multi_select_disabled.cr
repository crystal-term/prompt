require "../src/term-prompt"

prompt = Term::Prompt.new

drinks = [
  "bourbon",
  {name: "sake", disabled: "(out of stock)"},
  "vodka",
  {name: "beer", disabled: "(out of stock)"},
  "wine",
  "whisky"
]

answer = prompt.multi_select("Choose your favourite drink", drinks)
puts answer
