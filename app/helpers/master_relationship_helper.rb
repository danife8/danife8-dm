module MasterRelationshipHelper
  def priority_options(next_priority)
    options = [["N/A", ""]]
    options << [next_priority, next_priority] unless next_priority.nil?
    options
  end

  def cpm_non_applicable?(cpm)
    cpm.nil? || cpm.zero?
  end

  def cpm_to_currency(cpm)
    return "N/A" if cpm_non_applicable?(cpm)

    number_to_currency(cpm)
  end
end
