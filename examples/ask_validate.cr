require "../src/term-prompt"

prompt = Term::Prompt.new

folder_validator = Proc(Term::Prompt::Question, String?, Bool).new do |question, value|
  return false unless value
  unless Dir.exists?(value)
    question.errors << "Directory does not exist"
    return false
  end
  true
end

prompt.ask("Folder name:", required: true, validators: [folder_validator])
