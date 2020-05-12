<div align="center">
  <img src="./assets/term-logo.png" alt="term logo">
</div>

# Term::Prompt

![spec status](https://github.com/crystal-term/prompt/workflows/specs/badge.svg)

> A terminal prompt for tasks that have non-deterministic time frame.

**Term::Screen** provides an independent prompt component for crystal-term.

[![asciicast](https://asciinema.org/a/acKxSZcBD3I8BUlDBHtw02qtJ.svg)](https://asciinema.org/a/acKxSZcBD3I8BUlDBHtw02qtJ)

## Features

- Number of prompt types for gathering user input
- A robust API for validating complex inputs
- User friendly error feedback
- Intuitive DSL for creating complex menus
- Ability to page long menus

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     term-prompt:
       github: crystal-term/prompt
   ```

2. Run `shards install`

## Usage

In order to start asking questions, you need to first create a prompt:

```crystal
require "term-prompt"

prompt = Term::Prompt.new
```

And then call `ask` with the question for a simple input:

```crystal
prompt.ask("What is your name?", default: ENV["USER"])
# => What is your name? (watzon)
```

To ask for confirmation you can use `yes?` if you want the default answer to be yes, or `no?` if you want the default to be no. The return value will be a `Bool`.

```crystal
prompt.yes?("Do you love Crystal?")
# Do you love Crystal? (Y/n)
```

If you want to hide the input from prying eyes, you can use `mask`:

```crystal
prompt.mask("Please enter your password:")
# => Please enter your password: ••••••••••••
```

Asking question with list of options couldn't be easier using `select` like so:

```crystal
prompt.select("Choose your destiny?", %w(Scorpion Kano Jax))
# =>
# Choose your destiny? (Use ↑/↓ arrow keys, press Enter to select)
# ‣ Scorpion
#   Kano
#   Jax
```

Also, asking multiple choice questions is a breeze with multi_select:

```crystal
choices = %w(vodka beer wine whisky bourbon)
prompt.multi_select("Select drinks?", choices)
# =>
# Select drinks? (Use ↑/↓ arrow keys, press Space to select and Enter to finish)"
# ‣ ⬡ vodka
#   ⬡ beer
#   ⬡ wine
#   ⬡ whisky
#   ⬡ bourbon
```

To ask for a selection from enumerated list you can use enum_select:

```crystal
choices = %w(emacs nano vim)
prompt.enum_select("Select an editor?", choices)
# =>
# Select an editor?
#   1) emacs
#   2) nano
#   3) vim
#   Choose 1-3 [1]:
```

If you wish to collect more than one answer use collect:

```crystal
result = prompt.collect do |c|
  c.key(:name).ask("Name?")

  c.key(:age).ask("Age?")

  c.key(:address) do |c|
    c.key(:street).ask("Street?", required: true)
    c.key(:city).ask("City?")
    c.key(:zip).ask("Zip?", match: /\A\d{5}\Z/)
  end
end
# =>
# {:name => "Chris", :age => 27, :address => {:street => "Street", :city => "City", :zip => "12345"}}
```

## API

Coming soon

## Contributing

1. Fork it (<https://github.com/watzon/prompt/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
