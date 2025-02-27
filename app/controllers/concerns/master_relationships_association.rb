# This concern manages abstract logic reused across multiple controllers, all related to Master Relationship associations.
# Refer to the Master Relationship model for details on the associated tables.
module MasterRelationshipsAssociation
  extend ActiveSupport::Concern

  included do
    before_action :authorize!
    before_action :set_default_per

    expose :next_position, -> { collection.maximum("position") + 1 }
    expose :new_resource, -> { policy_model.new }
    expose :form_object_name, -> { controller_name.singularize.to_sym }

    def create
      # Override inherited create action because we need to render :index instead of :new if something goes wrong
      self.new_resource = model.new(permitted_params)
      if new_resource.save
        redirect_to index_path, notice: "#{display_model_name} was successfully created."
      else
        render :index, status: 422
      end
    end

    def update
      # Override inherited update action because we need to render :index instead of :edit if something goes wrong
      if resource.update(permitted_params)
        redirect_to index_path, notice: "#{display_model_name} was successfully updated."
      else
        render :index, status: 422
      end
    end

    def destroy
      destroy! do |deleted|
        redirect_to index_path,
          notice: deleted ? "#{display_model_name} was successfully deleted." : "There was a problem deleting the #{display_model_name}. It cannot be deleted because it has associated Master Relationships."
      end
    end

    def index_path
      polymorphic_path(controller_name.to_sym)
    end

    def update_path(resource)
      polymorphic_path(resource)
    end

    protected

    def set_default_per
      params[:per] = 250
    end

    def display_model_name
      controller_name.singularize.split("_").map(&:capitalize).join(" ")
    end

    def policy_model
      policy_scope(model).ordered
    end

    def permitted_params
      params.require(form_object_name).permit(
        policy(model).permitted_params
      )
    end
  end
end
