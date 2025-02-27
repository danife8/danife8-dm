# Inherited Resources concern speeds up development by making your controllers inherit all restful actions
# so you just have to focus on what is important. It makes your controllers more powerful and cleaner at the same time.
module InheritedResource
  extend ActiveSupport::Concern

  included do
    before_action :authorize!, except: %i[index]

    expose :collection, -> { policy_model.page(params[:page]).per(params[:per] || 10) }
    expose :resource, -> { params[:id] ? policy_model.find(params[:id]) : policy_model.new }

    def index
      authorize model
    end

    def show
    end

    def new
    end

    def edit
    end

    def create_resource
      self.resource = model.new(permitted_params)
      if resource.save
        if block_given?
          yield
        else
          redirect_to get_path(:index)
        end
      else
        respond_to do |format|
          format.html { render :new, status: 422 }
          format.json { render json: {errors: resource.errors.full_messages}, status: 422 }
        end
      end
    end

    alias_method :create!, :create_resource
    alias_method :create, :create_resource

    def update_resource
      if resource.update(permitted_params)
        if block_given?
          yield
        else
          redirect_to get_path(:index)
        end
      else
        respond_to do |format|
          format.html { render :edit, status: 422 }
          format.json { render json: {errors: resource.errors.full_messages}, status: 422 }
        end
      end
    end

    alias_method :update!, :update_resource
    alias_method :update, :update_resource

    def destroy_resource
      deleted = resource.destroy
      if block_given?
        return yield deleted
      end

      if deleted
        redirect_to get_path(:index)
      else
        redirect_back(fallback_location: get_path(:index))
      end
    end

    alias_method :destroy!, :destroy_resource
    alias_method :destroy, :destroy_resource

    protected

    def authorize!
      authorize resource
    end

    def model
      controller_name.classify.constantize
    end

    def policy_model
      policy_scope(model)
    end

    def permitted_params
      raise t("inherited.errors.permitted_params")
    end

    private

    def get_path(action, params = {})
      {controller: controller_path, action: action}.merge(params)
    end
  end
end
