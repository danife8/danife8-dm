# frozen_string_literal: true

module MediaPlans
  class UpdateMediaPlanState
    def initialize(media_plan, params, current_user)
      @action = params[:media_plan][:action]
      @previous_action = media_plan.aasm_state
      @previous_user_action = media_plan.aasm_creator_state
      @media_plan = media_plan
      @params = params
      @current_user = current_user
    end

    def call
      validate_action!

      update!
    end

    attr_reader :media_plan, :action, :params, :current_user, :previous_action, :previous_user_action

    protected

    def validate_action!
      raise ArgumentError unless ["submit", "update", "approve", "reject"].include?(action)
    end

    def error_message
      {
        submit: build_error_message("submitting for review"),
        update: build_error_message("updating"),
        approve: build_error_message("approving"),
        reject: build_error_message("rejecting")
      }[action.to_sym]
    end

    def success_message
      {
        submit: build_success_message("submitted for review"),
        update: build_success_message("updated"),
        approve: build_success_message("approved"),
        reject: build_success_message("rejected")
      }[action.to_sym]
    end

    def media_plan_output_attributes
      media_plan_output_rows_params.merge(
        id: media_plan.media_plan_output.id
      )
    end

    def media_plan_output_rows_params
      media_plan_output_params_dup = media_plan_output_params.dup

      media_plan_output_params_dup["media_plan_output_rows_attributes"].each do |_, row_attrs|
        unless row_attrs["id"].present?
          mrt = MasterRelationship.where(
            campaign_objective: media_plan.media_brief.campaign_objective,
            campaign_initiative: media_plan.media_brief.campaign_initiative,
            campaign_channel_id: row_attrs["campaign_channel_id"],
            target_strategy_id: row_attrs["target_strategy_id"],
            target_id: row_attrs["target_id"],
            ad_format_id: row_attrs["ad_format_id"],
            media_platform_id: row_attrs["media_platform_id"]
          ).ordered.first

          impressions = if mrt.nil? || mrt.cpm.nil? || mrt.cpm.zero?
            0.00
          else
            (media_plan.media_brief.campaign_budget / mrt.cpm) * 1000
          end

          row_attrs["master_relationship_id"] = mrt&.id
          row_attrs["impressions"] = impressions
          row_attrs["position"] = media_plan.media_plan_output.media_plan_output_rows.maximum("position").to_i + 1
        end
      end

      media_plan_output_params_dup
    end

    def update!
      media_plan.assign_attributes(
        action_params.merge(media_plan_output_attributes:)
      )

      # We do not transition the media plan if this or media plan output is invalid
      if media_plan.invalid? || media_plan.media_plan_output.invalid?
        return {success: false, message: error_message}
      end

      assign_modified_by_at

      # Transition the media plan if action is not update
      unless action == "update"
        media_plan.send(:"#{author}_#{action}")
      end

      if media_plan.save
        {success: true, message: success_message}
      else
        restore_media_plan_prev_state_with_errors

        {success: false, message: error_message}
      end
    rescue AASM::InvalidTransition, StandardError => e
      Rails.logger.error(e)
      {success: false, message: error_message}
    end

    def restore_media_plan_prev_state_with_errors
      errors = media_plan.errors.dup
      media_plan.update(aasm_state: previous_action, aasm_creator_state: previous_user_action)
      errors.each { |e| media_plan.errors.add(e.attribute, e.message) }
    end

    def author
      current_user.reviewer? ? "reviewer" : "user"
    end

    def assign_modified_by_at
      media_plan.media_plan_output.send(:"modified_by_#{author}_at=", media_plan.media_plan_output.modified? ? Time.zone.now : nil)
    end

    def build_error_message(ongoing_action)
      "There was a problem #{ongoing_action} the Media Plan. Please try again."
    end

    def build_success_message(past_action)
      "The Media Plan was successfully #{past_action}."
    end

    def media_plan_output_params
      params.require(:media_plan_output).permit(
        media_plan_output_rows_attributes: [
          :_destroy,
          :ad_format_id,
          :amt,
          :campaign_channel_id,
          :id,
          :impressions,
          :media_platform_id,
          :target_id,
          :target_strategy_id
        ]
      )
    end

    def action_params
      params.require(:media_plan).permit(:approve_comment, :reject_comment, :user_approve_comment, :user_reject_comment)
    end
  end
end
