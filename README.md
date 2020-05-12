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

## Interface

### `#ask`

In order to ask a basic question, do:

```crystal
prompt.ask("What is your name?")
```

However the `Question` class is far more robust than just that, and `#ask` accepts all of the same options that `Question.new` does.

```crystal
prompt.ask("What is your name?", required: true, match: /[a-z\s]+/i)
```

#### `:default`

The `default` option is used if the user presses the return key without entering a value:

```crystal
prompt.ask("What is your name?", default: "Anonymous")
# =>
# What is your name? (Anonymous)
```

#### `:value`

To pre-populate the input line for editing use `value` option:

```crystal
prompt.ask("What is your name?", value: "Chris")
# =>
# What is your name? Piotr
```

#### `:echo`

To control whether the input is shown back in terminal or not use `echo` option like so:

```crystal
prompt.ask("Password:", echo: false)
```

#### `:required`

To ensure that the input is provided, use the `required` option:

```crystal
prompt.ask("What's your phone number?", required: true)
# What's your phone number?
# >> Value is required
```

#### `:validators`

Validators allow you to ensure that an input matches a specific constraint. `validators` is an array of `Validator` objects, or procs which match `Proc(Question, String?, Bool)`.

```crystal
class NameValidator < Term::Prompt::Validator
  def call(question : Question, value : String?) : Bool
    if name = value
      names = name.split(/\s+/)
      if names.size < 2
        question.errors << "Enter your full name"
        return false
      end
    end
    true
  end
end

prompt.ask("What is your name?", required: true, validators: [NameValidator.new])
```

### `#keypress`

In order to await a single keypress, you can use `#keypress`:

```crystal
prompt.keypress("Press any key")
# Press any key
# => a
```

By default any key is accepted but you can limit keys by using `:keys` option. Any key event names such as `:space` or `:ctrl_k` are valid:

```crystal
prompt.keypress("Press space or enter to continue", keys: [:space, :return])
```

### `#mask`

f you require input of confidential information use `mask` method. By default each character that is printed is replaced by a `•` symbol. All configuration options applicable to `#ask` method can be used with `mask` as well.

```crystal
prompt.mask("What is your secret?")
# => What is your secret? ••••
```

The masking character can be changed by passing the `:mask` option:

```crystal
heart = prompt.decorate(prompt.symbols[:heart] + " ", :magenta)
prompt.mask("What is your secret?", mask: heart)
# => What is your secret? ❤  ❤  ❤  ❤  ❤
```

If you don't wish to show any output use `:echo` option like so:

```crystal
prompt.mask("What is your secret?", echo: false)
```

### `#yes?`/`#no?`

In order to display a query asking for boolean input from user use yes? like so:

```crystal
prompt.yes?("Do you like Ruby?")
# =>
# Do you like Ruby? (Y/n)
```

You can further customize question by passing `suffix`, `positive`, and `negative` options. The `suffix` changes text of available options, the `positive` changes the display string for successful answer and `negative` changes the display string for a negative answer. The final value is a boolean provided the `convert` option evaluates to boolean.

It's enough to provide the `suffix` option for the prompt to accept matching answers with correct labels:

```crystal
prompt.yes?("Are you a human?", suffix: "Yup/nope")
# =>
# Are you a human? (Yup/nope)
```

Alternatively, instead of `suffix` option you can provide `positive` and `negative` labels:

```crystal
prompt.yes?("Are you a human?") do |q|
  q.default false
  q.positive "Yup"
  q.negative "Nope"
end
# =>
# Are you a human? (yup/Nope)
```

There is also the opposite for asking the confirmation of a negative question:

```crystal
prompt.no?('Do you hate Crystal?')
# =>
# Do you hate Crystal? (y/N)
```

Similar to the `#yes?` method, you can supply the same options to customize the question.

### menu choices

There are several ways to add choices to the below menu types. The simplest is to create an array of values:

```crystal
choices = %w(small medium large)
```

By default the choice name is also the value the prompt will return when selected. To provide custom values, you can provide a named tuple with keys as choice names and their respective values:

```crystal
choices = {small: "1", medium: "2", large: "3"}
```

Unfortunately for now values have to be strings.

Finally, you can define an array of choices where each choice is a hash value with `:name` & `:value` keys which can include other options for customizing individual choices:

```crystal
choices = [
  {name: "small", value: "1"},
  {name: "medium", value: "2", disabled: "(out of stock)"},
  {name: "large", value: "3"}
]
```

You can specify `:key` as an additional option which will be used as short name for selecting the choice via keyboard key press.

Another way to create menu with choices is using the DSL and the choice method. For example, the previous array of choices with hash values can be translated as:

```crystal
prompt.select("Which size?") do |menu|
  menu.choice name: "small",  value: "1"
  menu.choice name: "medium", value: "2", disabled: "(out of stock)"
  menu.choice name: "large",  value: "3"
end
```

or in a more compact way:

```crystal
prompt.select("Which size?") do |menu|
  menu.choice "small",  "1"
  menu.choice "medium", "2", disabled: "(out of stock)"
  menu.choice "large",  "3"
end
```

#### `:disabled`

The `:disabled` key indicates that a choice is currently unavailable to select. Disabled choices are displayed with a cross `✘` character next to them. If the choice is disabled, it cannot be selected. The value for the `:disabled` item is used next to the choice to provide reason for excluding it from the selection menu. For example:

```crystal
choices = [
  {name: 'small', value: "1"},
  {name: 'medium', value: "2", disabled: "(out of stock)"}
  {name: 'large', value: "3"}
]
```

### `#select`

For asking questions involving list of options use the `select` method by passing a question and possible choices:

```crystal
prompt.select("Choose your destiny?", %w(Scorpion Kano Jax))
# =>
# Choose your destiny? (Use ↑/↓ arrow keys, press Enter to select)
# ‣ Scorpion
#   Kano
#   Jax
```

You can also provide options through DSL using the `choice` method for single entry and/or `choices` for more than one choice:

```crystal
prompt.select("Choose your destiny?") do |menu|
  menu.choice "Scorpion"
  menu.choice "Kano"
  menu.choice "Jax"
end
# =>
# Choose your destiny? (Use ↑/↓ arrow keys, press Enter to select)
# ‣ Scorpion
#   Kano
#   Jax
```

By default the choice name is used as return value, but you can provide custom values:

```crystal
prompt.select("Choose your destiny?") do |menu|
  menu.choice "Scorpion", "1"
  menu.choice "Kano", "2"
  menu.choice "Jax", "Nice choice captain!"
end
# =>
# Choose your destiny? (Use ↑/↓ arrow keys, press Enter to select)
# ‣ Scorpion
#   Kano
#   Jax
```

If you wish you can also provide a simple named tuple to denote choice name and its value like so:

```crystal
choices = {"Scorpion" => "1", "Kano" => "2", "Jax" => "3"}
prompt.select("Choose your destiny?", choices)
```

To mark particular answer as selected use `default` with index of the option starting from 1:

```crystal
prompt.select("Choose your destiny?") do |menu|
  menu.default 3

  menu.choice "Scorpion", "1"
  menu.choice "Kano", "2"
  menu.choice "Jax", "3"
end
# =>
# Choose your destiny? (Use ↑/↓ arrow keys, press Enter to select)
#   Scorpion
#   Kano
# ‣ Jax
```

You can navigate the choices using the arrow keys. When reaching the top/bottom of the list, the selection does not cycle around by default. If you wish to enable cycling, you can pass `cycle: true` to select and `multi_select`:

```crystal
prompt.select("Choose your destiny?", %w(Scorpion Kano Jax), cycle: true)
# =>
# Choose your destiny? (Use ↑/↓ arrow keys, press Enter to select)
# ‣ Scorpion
#   Kano
#   Jax
```

For ordered choices set `separator` to any delimiter String. In that way, you can use arrows keys and numbers (0-9) to select the item.

```crystal
prompt.select("Choose your destiny?") do |menu|
  menu.separator ")"

  menu.choice "Scorpion", "1"
  menu.choice "Kano", "2"
  menu.choice "Jax", "3"
end
# =>
# Choose your destiny? (Use ↑/↓ arrow or number (0-9) keys, press Enter to select)
#   1) Scorpion
#   2) Kano
# ‣ 3) Jax
```

You can configure the help message and/or marker like so:

```crystal
choices = %w(Scorpion Kano Jax)
prompt.select("Choose your destiny?", choices, help: "(Bash keyboard)", symbols: {marker: '>'})
# =>
# Choose your destiny? (Bash keyboard)
# > Scorpion
#   Kano
#   Jax
```

#### `:page_size`

By default the menu is paginated if selection grows beyond 6 items. To change this setting use `:page_size` option.

```crystal
letters = ("A".."Z").to_a
prompt.select("Choose your letter?", letters, page_size: 4)
# =>
# Which letter? (Use ↑/↓ and ←/→ arrow keys, press Enter to select)
# ‣ A
#   B
#   C
#   D
```

You can also customize the page navigation text using `:help` option:

```crystal
letters = ("A".."Z").to_a
prompt.select("Choose your letter?") do |menu|
  menu.page_size 4
  menu.help "(Wiggle thy finger up/down and left/right to see more)"
  menu.choices letters
end
# =>
# Which letter? (Wiggle thy finger up/down and left/right to see more)
# ‣ A
#   B
#   C
#   D
```

#### `:disabled`

To disable menu choice, use the `:disabled` key with a value that explains the reason for the choice being unavailable. For example, out of all warriors, Goro is currently injured:

```crystal
warriors = [
  "Scorpion",
  "Kano",
  { name: "Goro", disabled: "(injured)" },
  "Jax",
  "Kitana",
  "Raiden"
]
```

The disabled choice will be displayed with a cross ✘ character next to it and followed by an explanation:

```crystal
prompt.select("Choose your destiny?", warriors)
# =>
# Choose your destiny? (Use ↑/↓ arrow keys, press Enter to select)
# ‣ Scorpion
#   Kano
# ✘ Goro (injured)
#   Jax
#   Kitana
#   Raiden
```

#### `:filter`

To activate dynamic list searching by letter/number key presses use the `:filter` option:

```crystal
warriors = %w(Scorpion Kano Jax Kitana Raiden)
prompt.select("Choose your destiny?", warriors, filter: true)
# =>
# Choose your destiny? (Use ↑/↓ arrow keys, press Enter to select, and letter keys to filter)
# ‣ Scorpion
#   Kano
#   Jax
#   Kitana
#   Raiden
```

After the user presses "k":

```crystal
# =>
# Choose your destiny? (Filter: "k")
# ‣ Kano
#   Kitana
```

After the user presses "ka":

```crystal
# =>
# Choose your destiny? (Filter: "ka")
# ‣ Kano
```

Filter characters can be deleted partially or entirely via Backspace and Delete respectively.

If the user changes or deletes a filter, the choices previously selected remain selected.

## `#multi_select`

For asking questions involving multiple selections use the `#multi_select` method by passing the question and possible choices:

```crystal
choices = %w(vodka beer wine whisky bourbon)
prompt.multi_select("Select drinks?", choices)
# =>
#
# Select drinks? (Use ↑/↓ arrow keys, press Space to select and Enter to finish)"
# ‣ ⬡ vodka
#   ⬡ beer
#   ⬡ wine
#   ⬡ whisky
#   ⬡ bourbon
```

As a return value, `multi_select` will always return an array populated with the names of the choices. If you wish to return custom values for the available choices do:

```crystal
choices = {vodka: "1", beer: "2", wine: "3", whisky: "4", bourbon: "}
prompt.multi_select("Select drinks?", choices)

# Provided that vodka and beer have been selected, the function will return
# => ["1", "2"]
```

Similar to the `#select` method, you can also provide options through the DSL using the `choice` method for single entry and/or `choices` for more than one choice:

```crystal
prompt.multi_select("Select drinks?") do |menu|
  menu.choice :vodka, "1"
  menu.choice :beer, "2"
  menu.choice :wine, "3"
  menu.choices whisky: "4", bourbon: "5"
end
```

To mark choice(s) as selected use the `default` option with index(s) of the option(s) starting from 1:

```crystal
prompt.multi_select("Select drinks?") do |menu|
  menu.default 2, 5

  menu.choice :vodka,   "1"
  menu.choice :beer,    "2"
  menu.choice :wine,    "3"
  menu.choice :whisky,  "4"
  menu.choice :bourbon, "5"
end
# =>
# Select drinks? beer, bourbon
#   ⬡ vodka
#   ⬢ beer
#   ⬡ wine
#   ⬡ whisky
# ‣ ⬢ bourbon
```

Like select, for ordered choices set `separator` to any delimiter String. In that way, you can use arrows keys and the numbers (0-9) to select the item.

```crystal
prompt.multi_select("Select drinks?") do |menu|
  menu.separator ")"

  menu.choice :vodka,   "1"
  menu.choice :beer,    "2"
  menu.choice :wine,    "3"
  menu.choice :whisky,  "4"
  menu.choice :bourbon, "5"
end
# =>
# Select drinks? beer, bourbon
#   ⬡ 1) vodka
#   ⬢ 2) beer
#   ⬡ 3) wine
#   ⬡ 4) whisky
# ‣ ⬢ 5) bourbon
```

And when you press enter you will see the following selected:

```
# Select drinks? beer, bourbon
# => ["2", "5"]
```

Also like, `select`, the method takes an option `cycle` (which defaults to false), which lets you configure whether the selection should cycle around when reaching the top/bottom of the list:

```crystal
prompt.multi_select("Select drinks?", %w(vodka beer wine), cycle: true)
```

You can configure help message and/or marker like so

```crystal
choices = {vodka: "1", beer: "2", wine: "3", whisky: "4", bourbon: "5"}
prompt.multi_select("Select drinks?", choices, help: "Press beer can against keyboard")
# =>
# Select drinks? (Press beer can against keyboard)"
# ‣ ⬡ vodka
#   ⬡ beer
#   ⬡ wine
#   ⬡ whisky
#   ⬡ bourbon
```

By default the menu is paginated if selection grows beyond `6` items. To change this setting use the `:page_size` option:

```crystal
letters = ("A".."Z").to_a
prompt.multi_select("Choose your letter?", letters, page_size: 4)
# =>
# Which letter? (Use ↑/↓ and ←/→ arrow keys, press Space to select and Enter to finish)
# ‣ ⬡ A
#   ⬡ B
#   ⬡ C
#   ⬡ D
```

#### `:disabled`

To disable menu choice, use the `:disabled` key with a value that explains the reason for the choice being unavailable. For example, out of all drinks, the sake and beer are currently out of stock:

drinks = [
  "bourbon",
  {name: "sake", disabled: "(out of stock)"},
  "vodka",
  {name: "beer", disabled: "(out of stock)"},
  "wine",
  "whisky"
]

The disabled choice will be displayed with a cross `✘` character next to it and followed by an explanation:

```crystal
prompt.multi_select("Choose your favourite drink?", drinks)
# =>
# Choose your favourite drink? (Use ↑/↓ arrow keys, press Space to select and Enter to finish)
# ‣ ⬡ bourbon
#   ✘ sake (out of stock)
#   ⬡ vodka
#   ✘ beer (out of stock)
#   ⬡ wine
#   ⬡ whisky
```

#### `:echo`

To control whether the selected items are shown on the question header use the `:echo` option:

```crystal
choices = %w(vodka beer wine whisky bourbon)
prompt.multi_select("Select drinks?", choices, echo: false)
# =>
# Select drinks?
#   ⬡ vodka
#   ⬢ 2) beer
#   ⬡ 3) wine
#   ⬡ 4) whisky
# ‣ ⬢ 5) bourbon
```

#### `:filter`

To activate dynamic list filtering on letter/number typing, use the `:filter` option:

```crystal
choices = %w(vodka beer wine whisky bourbon)
prompt.multi_select("Select drinks?", choices, filter: true)
# =>
# Select drinks? (Use ↑/↓ arrow keys, press Space to select and Enter to finish, and letter keys to filter)
# ‣ ⬡ vodka
#   ⬡ beer
#   ⬡ wine
#   ⬡ whisky
#   ⬡ bourbon
```

#### `:filter`

To activate dynamic list filtering on letter/number typing, use the `:filter` option:

```crystal
choices = %w(vodka beer wine whisky bourbon)
prompt.multi_select("Select drinks?", choices, filter: true)
# =>
# Select drinks? (Use ↑/↓ arrow keys, press Space to select and Enter to finish, and letter keys to filter)
# ‣ ⬡ vodka
#   ⬡ beer
#   ⬡ wine
#   ⬡ whisky
#   ⬡ bourbon
```

After the user presses "w":

```
# Select drinks? (Filter: "w")
# ‣ ⬡ wine
#   ⬡ whisky
```

Filter characters can be deleted partially or entirely via Backspace and Delete respectively.

If the user changes or deletes a filter, the choices previously selected remain selected.

The filter option is not compatible with `:separator`.

#### `:min`

To force the minimum number of choices an user must select, use the `:min` option:

```crystal
choices = %w(vodka beer wine whisky bourbon)
prompt.multi_select("Select drinks?", choices, min: 3)
# =>
# Select drinks? (min. 3) vodka, beer
#   ⬢ vodka
#   ⬢ beer
#   ⬡ wine
#   ⬡ wiskey
# ‣ ⬡ bourbon
```

#### `:max`

To limit the number of choices an user can select, use the `:max` option:

```crystal
choices = %w(vodka beer wine whisky bourbon)
prompt.multi_select("Select drinks?", choices, max: 3)
# =>
# Select drinks? (max. 3) vodka, beer, whisky
#   ⬢ vodka
#   ⬢ beer
#   ⬡ wine
#   ⬢ whisky
# ‣ ⬡ bourbon
```

### `#enum_select`

In order to ask for standard selection from indexed list you can use `#enum_select` and pass question together with possible choices:

```crystal
choices = %w(emacs nano vim)
prompt.enum_select("Select an editor?")
# =>
#
# Select an editor?
#   1) nano
#   2) vim
#   3) emacs
#   Choose 1-3 [1]:
```

Similar to `select` and `multi_select`, you can provide question options through DSL using choice method and/or choices like so:

```crystal
choices = %w(nano vim emacs)
prompt.enum_select("Select an editor?") do |menu|
  menu.choice "nano",  "/bin/nano"
  menu.choice "vim",   "/usr/bin/vim"
  menu.choice "emacs", "/usr/bin/emacs"
end
# =>
#
# Select an editor?
#   1) nano
#   2) vim
#   3) emacs
#   Choose 1-3 [1]:
#
# Select an editor? /bin/nano
```

You can change the indexed numbers by passing `separator` option and the default option by using default like so

```crystal
choices = %w(nano vim emacs)
prompt.enum_select("Select an editor?") do |menu|
  menu.default 2
  menu.separator "."

  menu.choice "nano",  "/bin/nano"
  menu.choice "vim",   "/usr/bin/vim"
  menu.choice "emacs", "/usr/bin/emacs"
end
# =>
#
# Select an editor?
#   1. nano
#   2. vim
#   3. emacs
#   Choose 1-3 [2]:
#
# Select an editor? /usr/bin/vim
```

#### `:page_size`

By default the menu is paginated if selection grows beyond `6` items. To change this setting use `:page_size` configuration.

```crystal
letters = ("A".."Z").to_a
prompt.enum_select("Choose your letter?", letters, page_size: 4)
# =>
# Which letter?
#   1) A
#   2) B
#   3) C
#   4) D
#   Choose 1-26 [1]:
# (Press tab/right or left to reveal more choices)
```

#### `:disabled`

To make a choice unavailable use the `:disabled` option and, if you wish, provide a reason:

choices = [
  {name: "Emacs", disabled: "(not installed)"},
  "Atom",
  "GNU nano",
  {name: "Notepad++", disabled: "(not installed)"},
  "Sublime",
  "Vim"
]

The disabled choice will be displayed with a cross `✘` character next to it and followed by an explanation:

```crystal
prompt.enum_select("Select an editor", choices)
# =>
# Select an editor
# ✘ 1) Emacs (not installed)
#   2) Atom
#   3) GNU nano
# ✘ 4) Notepad++ (not installed)
#   5) Sublime
#   6) Vim
#   Choose 1-6 [2]:
```

### `#slider`

If you have constrained range of numbers for user to choose from you may consider using a `slider`.

The slider provides easy visual way of picking a value marked with the `●` symbol. You can set `:min` (defaults to 0), `:max`, and `:step` (defaults to 1) options to configure slider range:

```crystal
prompt.slider("Volume", max: 100, step: 5)
# =>
# Volume ──────────●────────── 50
# (Use arrow keys, press Enter to select)
```

You can also change the default slider formatting using the `:format`. The value must contain the `:slider` token to show current value and any `sprintf` compatible flag for number display, in our case `%d`:

```crystal
prompt.slider("Volume", max: 100, step: 5, default: 75, format: "|:slider| %d%%")
# =>
# Volume |───────────────●──────| 75%
# (Use arrow keys, press Enter to select)
```

As of now only whole numbers are supported.

If you wish to change the slider handle and the slider range display use `:symbols` option:

```crystal
prompt.slider("Volume", max: 100, step: 5, default: 75, symbols: {bullet: "x", line: "_"})
# =>
# Volume _______________x______ 75%
# (Use arrow keys, press Enter to select)
```

Slider can be configured through a DSL as well:

```crystal
prompt.slider("What size?") do |range|
  range.max 100
  range.step 5
  range.default 75
  range.format "|:slider| %d%"
end
# =>
# Volume |───────────────●──────| 75%
# (Use arrow keys, press Enter to select)
```

### `#say`

To simply print message out to standard output use `say` like so:

```crystal
prompt.say(...)
```

The `say` method also accepts option `:color` which supports all the colors provided by [Cor](https://github.com/watzon/cor), as well as a Cor object itself, or an `{R, G, B}` tuple.

`Term::Prompt` provides more specific versions of `say` method to better express intention behind the message such as `ok`, `warn`, and `error`.

#### `#ok`

To print message(s) in green do:

```crystal
prompt.ok(...)
```

#### `#warn`

To print message(s) in yellow do:

```crystal
prompt.warn(...)
```

#### `#error`

To print message(s) in red do:

```crystal
prompt.error(...)
```

## Settings

### `:symbols`

Many prompts use symbols to display information. You can overwrite the default symbols for all the prompts using the `:symbols` key and hash of symbol names as value:

```crystal
prompt = Term::Prompt.new(symbols: { marker: ">" })
```

The following symbols can be overwritten:


| Symbols     | Unicode | ASCII |
| ----------- |:-------:|:-----:|
|  tick       | `✓`     | `√`   |
|  cross      | `✘`     | `x`   |
|  marker     | `‣`     | `>`   |
|  dot        | `•`     | `.`   |
|  bullet     | `●`     | `O`   |
|  line       | `─`     | `-`   |
|  radio_on   | `⬢`     | `(*)` |
|  radio_off  | `⬡`     | `( )` |
|  arrow_up   | `↑`     | `↑`   |
|  arrow_down | `↓`     | `↓`   |
|  arrow_left | `←`     | `←`   |
|  arrow_right| `→`     | `→`   |

### `:palette`

Colors are fetched from a `Palette` object, which contains 4 different colors. Their names and defaults are as follows:

- `enabled` - `:dark_grey`
- `active` - `:green`
- `help` - `:dim_grey`
- `error` - `:red`
- `warning` - `:yellow`

You can provide your own palette object to change the colors. For example, to change the active color to pink:

```crystal
palette = Term::Prompt::Palette.new(active: :pink)
prompt = Term::Prompt.new(palette: palette)
```

### `:interrupt`

By default `InputInterrupt` error will be raised when the user hits the interrupt key (Control-C). However, you can customize this behaviour by passing the `:interrupt` option. The available options are:

    :signal - sends interrupt signal
    :exit - exists with status code
    :noop - skips handler

For example, to send interrupt signal do:

```crystal
prompt = Term::Prompt.new(interrupt: :signal)
```

### `:prefix`

You can prefix each question asked using the `:prefix` option. This option can be applied either globally for all prompts or individual for each one:

```crystal
prompt = Term::Prompt.new(prefix: "[?] ")
```

## Contributing

1. Fork it (<https://github.com/watzon/prompt/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
