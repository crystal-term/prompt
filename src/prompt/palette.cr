module Term
  class Prompt
    record Palette,
      enabled = Cor.color(:dark_grey),
      active = Cor.color(:green),
      help = Cor.color(:dim_grey),
      error = Cor.color(:red),
      warning = Cor.color(:yellow)
  end
end
