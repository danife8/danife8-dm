namespace :media_plan_output_rows do
  desc "Reprocess MediaPlanOutputRow records with null master_relationship_id"
  task reprocess: :environment do
    def find_master_relationship(row)
      mrt = MasterRelationship.where(
        campaign_objective: row.media_plan_output.media_plan.media_brief.campaign_objective,
        campaign_initiative: row.media_plan_output.media_plan.media_brief.campaign_initiative,
        campaign_channel_id: row.campaign_channel_id,
        target_strategy_id: row.target_strategy_id,
        target_id: row.target_id,
        ad_format_id: row.ad_format_id,
        media_platform_id: row.media_platform_id
      ).ordered.first

      return mrt if mrt.present?

      # Less Specific search
      MasterRelationship.where(
        campaign_objective: row.media_plan_output.media_plan.media_brief.campaign_objective,
        campaign_initiative: row.media_plan_output.media_plan.media_brief.campaign_initiative,
        campaign_channel_id: row.campaign_channel_id,
        target_strategy_id: row.target_strategy_id
      ).ordered.first
    end

    batch_size = 100

    MediaPlanOutputRow.where(master_relationship_id: nil).find_in_batches(batch_size: batch_size) do |batch|
      ActiveRecord::Base.transaction do
        batch.each do |row|
          mrt = find_master_relationship(row)

          if mrt.present?
            row.update!(master_relationship_id: mrt.id)
            puts "MasterRelationship found for row: #{row.id}"
          else
            puts "MasterRelationship not found for row: #{row.id}"
          end
        rescue => e
          puts "Error processing row #{row.id}: #{e.message}"
        end
      end
    end
  end
end
