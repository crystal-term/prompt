require "../src/term-prompt"

prompt = Term::Prompt.new

# Example 1: Select any file
puts "=== File Selection ==="
file = prompt.file_select("Choose a file to edit:")
puts "You selected: #{file}"

puts "\n=== Directory Selection ==="
# Example 2: Select a directory
directory = prompt.directory_select("Choose a project directory:", 
  start_path: Dir.current)
puts "You selected: #{directory}"

puts "\n=== Filtered File Selection ==="
# Example 3: Select only Crystal files
crystal_file = prompt.file_select("Choose a Crystal file:", 
  filter: [".cr"],
  start_path: "src/",
  help: "(Only .cr files shown, ↑/↓ navigate, Enter select)")
puts "You selected: #{crystal_file}"

puts "\n=== Path Selection ==="
# Example 4: Select file or directory
path = prompt.path_select("Choose any path:", 
  show_hidden: true,
  help: "(Files and directories shown, ← up, → enter dir)")
puts "You selected: #{path}"