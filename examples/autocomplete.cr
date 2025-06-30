require "../src/term-prompt"

prompt = Term::Prompt.new

# Example 1: Framework selection
puts "=== Framework Selection ==="
frameworks = %w[
  Rails Django Flask Laravel Express
  React Vue Angular Svelte NextJS
  Spring Boot ASP.NET Crystal Lucky
]

answer = prompt.autocomplete("Choose a framework:", frameworks)
puts "You selected: #{answer}"

puts "\n=== Command Selection ==="
# Example 2: Command selection  
commands = %w[
  git-add git-commit git-push git-pull git-checkout
  git-branch git-merge git-rebase git-status git-log
  docker-build docker-run docker-ps docker-stop
  npm-install npm-start npm-test npm-build
]

command = prompt.autocomplete("Enter a command:", commands, 
  help: "(Type to search commands, Tab to complete)")
puts "You entered: #{command}"