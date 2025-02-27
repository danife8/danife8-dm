module Filterable
  extend ActiveSupport::Concern

  included do
    expose :clients, -> { policy_scope(Client).ordered }
    expose :states, -> { model.valid_aasm_states }
    expose :form_path, -> do
      if params[:action] != "index"
        polymorphic_path(controller_name.to_sym, action: params[:action])
      else
        polymorphic_path(controller_name.to_sym)
      end
    end
  end

  protected

  def filter_truly_keys(parameters)
    parameters.select { |_k, v| v == "true" }.keys
  end

  def truly_keys_for(param_key)
    return nil unless filter_params[param_key].present?

    filter_truly_keys(filter_params[param_key]).presence
  end

  def filter_params
    params.fetch(:filter, {}).permit(:q, client_ids: {}, aasm_states: {})
  end

  def sort_params
    params.fetch(:sort, nil)
  end

  def policy_model
    scope = policy_scope(model)

    if filter_params[:q].present?
      scope = scope.search_by_title(filter_params[:q])
    end

    truly_states = truly_keys_for(:aasm_states)
    scope = scope.by_aasm_states(truly_states) if truly_states

    truly_clients = truly_keys_for(:client_ids)
    scope = scope.by_client_ids(truly_clients) if truly_clients

    if sort_params.present?
      scope.order_by(*sort_params.split("."))
    else
      scope.ordered
    end
  end
end
