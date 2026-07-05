require "./spec_helper"

describe Term::Prompt::FileSelect do
  it "selects the active file on enter" do
    with_temp_dir("term-prompt-file-select") do |dir|
      file_path = File.join(dir, "alpha.txt")
      File.write(file_path, "alpha")

      picker = Term::Prompt::FileSelect.new(term_prompt, start_path: dir, file_only: true)

      picker.keydown
      picker.keyenter

      picker.spec_done.should be_true
      picker.spec_answer.should eq(file_path)
    end
  end

  it "uses the start_path option as the initial directory" do
    with_temp_dir("term-prompt-file-select") do |dir|
      picker = Term::Prompt::FileSelect.new(term_prompt, start_path: dir)

      picker.spec_current_path.should eq(dir)
      picker.spec_answer.should eq(dir)
    end
  end

  it "enters and leaves directories with right and left keys" do
    with_temp_dir("term-prompt-file-select") do |dir|
      nested = File.join(dir, "nested")
      Dir.mkdir(nested)
      picker = Term::Prompt::FileSelect.new(term_prompt, start_path: dir)

      picker.keydown
      picker.keyright
      picker.spec_current_path.should eq(nested)

      picker.keyleft
      picker.spec_current_path.should eq(dir)
    end
  end

  it "keeps an empty temp directory unfinished until a selectable entry is chosen" do
    with_temp_dir("term-prompt-file-select") do |dir|
      picker = Term::Prompt::FileSelect.new(term_prompt, start_path: dir, file_only: true)

      picker.entries.map(&.[0]).should eq([".."])
      plain(picker.spec_render_question).should contain("Path: #{dir}")
      picker.spec_done.should be_false
    end
  end
end
