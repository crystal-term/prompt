require "../src/term-prompt"

prompt = Term::Prompt.new

puts "Testing multi_select with min and max requirements"
puts "=" * 50

# Test with min requirement
puts "\n1. Select at least 2 drinks:"
choices = %w[Vodka Gin Rum Whisky Beer Wine]

begin
  selected = prompt.multi_select("Select drinks:", choices) do |menu|
    menu.min = 2
    menu.max = 4
    menu.help = "(Use arrows, space to select, Enter to finish)"
  end
  puts "✓ You selected #{selected.size} items: #{selected.inspect}"
rescue ex
  puts "✗ Error: #{ex.message}"
end

# Test with default values
puts "\n2. Testing with default selections:"
selected = prompt.multi_select("Select drinks:", choices) do |menu|
  menu.min = 2
  menu.max = 4
  menu.default = [1, 3]  # Vodka and Rum
end
puts "✓ You selected #{selected.size} items: #{selected.inspect}"

# Test without constraints
puts "\n3. Select any number of drinks:"
selected = prompt.multi_select("Select drinks:", choices)
puts "✓ You selected #{selected.size} items: #{selected.inspect}"

puts "\nDone!"