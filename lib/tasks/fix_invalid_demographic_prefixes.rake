namespace :data_fixes do
  desc "Fixes invalid demographic_details_prefixes in MediaBriefs"
  task fix_invalid_demographic_prefixes: :environment do
    MediaBrief.find_each do |media_brief|
      prefix_fields = [
        :demographic_details1_prefix,
        :demographic_details2_prefix,
        :demographic_details3_prefix,
        :demographic_details4_prefix,
        :demographic_details5_prefix
      ]

      updated = false

      prefix_fields.each do |field|
        value = media_brief.send(field)
        if value.present? && !DemographicDetailsPrefix.find(value)
          media_brief[field] = nil
          updated = true
        end
      end

      if updated && media_brief.save
        puts "Updated MediaBrief ID: #{media_brief.id}"
      elsif updated
        puts "Failed to update MediaBrief ID: #{media_brief.id}. Errors: #{media_brief.errors.full_messages.join(", ")}"
      end
    end
  end
end
