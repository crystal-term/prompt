require "json"
require "../src/term-prompt"

prompt = Term::Prompt.new(prefix: "[?] ")

result = prompt.collect do |c|
  c.key(:name).ask("Name?")

  c.key(:age).ask("Age?", convert: :int) do |q|
    q.validate { |v| v > 0 && v < 150 }
    q.messages[:valid?] = "Age must be between 1 and 149"
  end

  c.key(:address) do |c|
    c.key(:street).ask("Street?", required: true)
    c.key(:city).ask("City?")
    c.key(:zip).ask("Zip?", match: /\A\d{5}\Z/)
  end
end

puts
puts result.to_pretty_json
