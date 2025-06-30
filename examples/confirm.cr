require "../src/term-prompt"

prompt = Term::Prompt.new

# Example 1: Regular confirmation
puts "=== Regular Confirmation ==="
answer = prompt.confirm("Continue with operation?")
puts "Answer: #{answer}\n"

# Example 2: Destructive operation
puts "=== Destructive Operation ==="
answer = prompt.confirm("Delete all files in /tmp?", 
  destructive: true,
  warning: "This will permanently delete all files!")
puts "Answer: #{answer}\n"

# Example 3: Double confirmation
puts "=== Double Confirmation ==="
answer = prompt.confirm("Deploy to production?", 
  double_confirm: true)
puts "Answer: #{answer}\n"

# Example 4: Custom confirmation word
puts "=== Custom Confirmation Word ==="
answer = prompt.confirm("Reset database?", 
  destructive: true,
  confirmation_word: "RESET",
  warning: "This will erase all data permanently!")
puts "Answer: #{answer}\n"

# Example 5: Require exact match (non-destructive)
puts "=== Exact Match Required ==="
answer = prompt.confirm("Proceed with backup?", 
  require_exact: true,
  confirmation_word: "backup")
puts "Answer: #{answer}"