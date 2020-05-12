module Term
  class Prompt
    module Symbols
      KEYS = {
        :tick => "✓",
        :cross => "✘",
        :star => "★",
        :square => "◼",
        :square_empty => "◻",
        :dot => "•",
        :bullet => "●",
        :bullet_empty => "○",
        :marker => "‣",
        :line => "─",
        :pipe => "|",
        :ellipsis => "…",
        :radio_on => "⬢",
        :radio_off => "⬡",
        :checkbox_on => "☒",
        :checkbox_off => "☐",
        :circle => "◯",
        :circle_on => "ⓧ",
        :circle_off => "Ⓘ",
        :arrow_up => "↑",
        :arrow_down => "↓",
        :arrow_up_down => "↕",
        :arrow_left => "←",
        :arrow_right => "→",
        :arrow_left_right => "↔",
        :heart => "♥",
        :diamond => "♦",
        :club => "♣",
        :spade => "♠"
      }

      WIN_KEYS = {
        :tick => "√",
        :cross => "x",
        :star => "*",
        :square => "[█]",
        :square_empty => "[ ]",
        :dot => ".",
        :bullet => "O",
        :bullet_empty => "○",
        :marker => ">",
        :line => "-",
        :pipe => "|",
        :ellipsis => "...",
        :radio_on => "(*)",
        :radio_off => "( )",
        :checkbox_on => "[×]",
        :checkbox_off => "[ ]",
        :circle => "( )",
        :circle_on => "(x)",
        :circle_off => "( )",
        :arrow_up => "↑",
        :arrow_down => "↓",
        :arrow_up_down => "↕",
        :arrow_left => "←",
        :arrow_right => "→",
        :arrow_left_right => "↔",
        :heart => "♥",
        :diamond => "♦",
        :club => "♣",
        :spade => "♠"
      }

      def self.symbols
        @@symbols ||= KEYS
      end
    end # Symbols
  end
end
