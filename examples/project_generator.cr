require "../src/term-prompt"

prompt = Term::Prompt.new

name = prompt.ask("Project name:")

template = prompt.select("Choose a template:") do |menu|
  menu.choice "Web"
  menu.choice "API"
  menu.choice "Skeleton"
end

gen_license = prompt.yes?("Would you like to generate a license?")

if gen_license
  license = prompt.select("License format?", ["Apache", "MIT", "GPL", "LGPL", "Other"])
  if license == "Other"
    license = prompt.ask("License SPDX identifier:")
  end
end

prompt.ok("Project generated! You can find it at ./#{name.to_s.underscore}.")

puts
pp({
  name: name,
  template: template,
  gen_license: gen_license,
  license: license
})
