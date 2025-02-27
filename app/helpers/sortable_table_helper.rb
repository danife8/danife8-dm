module SortableTableHelper
  def row_class(sortable_field)
    sortable_field.present? ? "js-sortable-row sortable-row" : "not-sortable-row"
  end

  def row_target(sortable_field)
    sortable_field.present? ? "row" : ""
  end
end
