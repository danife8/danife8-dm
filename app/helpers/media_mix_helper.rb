module MediaMixHelper
  def budget_percentage(budget)
    return "-" if budget.zero?

    formatted_budget = sprintf("%.2f", budget)
    formatted_budget.gsub!(/\.0{1,2}\z/, "")

    "#{formatted_budget}%"
  end

  def currency(number)
    return "-" if number.zero?

    number_to_currency(number)
  end

  def sum_percentages(engine)
    primary_percentages = engine.primary_channels.sum { |channel| channel.platform_budget }
    secondary_percentages = engine.secondary_channels.sum { |channel| channel.platform_budget }

    budget_percentage(primary_percentages + secondary_percentages)
  end

  def sum_amts(engine, transform_to_currency = true)
    total_amts = sum_channel_amts(engine.primary_channels) + sum_channel_amts(engine.secondary_channels)
    transform_to_currency ? currency(total_amts) : total_amts
  end

  def sum_channel_amts(channels)
    channels.sum { |channel| channel.target_strategies.sum { |st| st[:amt] } }
  end

  def is_retargeting(target_strategy)
    target_strategy.try(:label) == "Retargeting"
  end

  def media_mix_status(status, deleted = false)
    return "Archived" if deleted
    {active: "Active", modified: "Modified", approved: "Approved"}[status.to_sym] || ""
  end
end
