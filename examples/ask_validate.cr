require "../src/term-prompt"

prompt = Term::Prompt.new

folder_validator = Proc(Term::Prompt::Question, String?, Bool).new do |question, value|
  if value.nil?
    false
  elsif !Dir.exists?(value)
    question.errors << "Directory does not exist"
    false
  else
    true
  end
end

prompt.ask("Folder name:", required: true, validators: [folder_validator])
