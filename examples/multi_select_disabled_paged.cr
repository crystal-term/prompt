require "../src/term-prompt"

prompt = Term::Prompt.new

numbers = [
  {name: "1", disabled: "out"},
  "2",
  {name: "3", disabled: "out"},
  "4",
  "5",
  {name: "6", disabled: "out"},
  "7",
  "8",
  "9",
  {name: "10", disabled: "out"}
]

answer = prompt.multi_select("Which letter", numbers, page_size: 4, cycle: true)
puts answer
