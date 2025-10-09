module Term
  class Prompt
    record Palette,
      enabled = Color.color(:dark_grey),
      active = Color.color(:green),
      help = Color.color(:dim_grey),
      error = Color.color(:red),
      warning = Color.color(:yellow)
  end
end
