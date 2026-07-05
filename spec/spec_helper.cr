require "spec"
require "file_utils"
require "../src/term-prompt"

def term_prompt
  Term::Prompt.new
end

def key_event(value, key_name = nil)
  keys = {} of String => String
  keys[value] = key_name if key_name
  Term::Reader::KeyEvent.from(keys, value)
end

def plain(value)
  Term::Color.strip(value)
end

def with_temp_dir(prefix, &)
  dir = File.tempname(prefix)
  Dir.mkdir(dir)
  yield dir
ensure
  FileUtils.rm_rf(dir) if dir
end

class Term::Prompt::List
  def spec_setup_defaults
    setup_defaults
  end

  def spec_active
    @active
  end

  def spec_done
    @done
  end

  def spec_visible_names
    choices.map(&.name)
  end

  def spec_render_menu
    render_menu
  end

  def spec_answer
    answer
  end

  def spec_register_subscriptions
    @prompt.reader.clear_component_handlers
    register_subscriptions
  end
end

class Term::Prompt::MultiList
  def spec_selected_names
    selected_names
  end
end

class Term::Prompt::EnumList
  def spec_active
    @active
  end

  def spec_page_active
    @page_active
  end
end

class Term::Prompt::Slider
  def spec_setup_defaults
    @active = initial
  end

  def spec_active
    @active
  end

  def spec_done
    @done
  end

  def spec_answer
    answer
  end

  def spec_render_question
    render_question
  end

  def spec_render_slider
    render_slider
  end
end

class Term::Prompt::Expander
  def spec_setup_defaults
    setup_defaults
  end

  def spec_input
    @input
  end

  def spec_answer
    answer
  end

  def spec_choice_names
    @choices.map(&.name)
  end

  def spec_render_question
    render_question
  end

  def spec_render_menu
    render_menu
  end
end

class Term::Prompt::Autocomplete
  def spec_active
    @active
  end

  def spec_done
    @done
  end

  def spec_input
    @input
  end

  def spec_search_query
    @search_query
  end

  def spec_answer
    answer
  end

  def spec_suggestion_names
    suggestions.map(&.name)
  end

  def spec_render_question
    render_question
  end
end

class Term::Prompt::FileSelect
  def spec_active
    @active
  end

  def spec_current_path
    @current_path
  end

  def spec_done
    @done
  end

  def spec_result
    @result
  end

  def spec_answer
    answer
  end

  def spec_render_question
    render_question
  end
end

class Term::Prompt::EnhancedConfirm
  def spec_input
    @input
  end

  def spec_done
    @done
  end

  def spec_confirmations
    @confirmations
  end

  def spec_render_question
    render_question
  end
end

class Term::Prompt::Question
  def spec_done
    @done
  end

  def spec_input
    @input
  end

  def spec_render_question
    render_question
  end
end

class Term::Prompt::MaskQuestion
  def spec_done_masked
    @done_masked
  end
end

class Term::Prompt::Multiline
  def spec_lines_count
    @lines_count
  end
end
