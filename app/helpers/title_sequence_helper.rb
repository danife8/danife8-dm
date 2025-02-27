module TitleSequenceHelper
  def generate_media_title(model_class, user)
    return unless user.agency

    prefix = model_class.name.split(/(?=[A-Z])/).map(&:first).join.upcase

    date = Date.current
    formatted_date = date.strftime("%m.%d.%Y")

    media_count = model_class.joins(client: :agency)
      .where(clients: {agency_id: user.agency_id})
      .where(created_at: date.beginning_of_day..date.end_of_day)
      .count + 1

    media_number = format("%02d", media_count)

    "#{prefix}-#{media_number}-#{formatted_date}"
  end
end
