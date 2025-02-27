module MasterRelationshipsAssociationHelper
  def path_for(action, resource = nil)
    case action
    when :index, :create
      controller.index_path
    when :update, :delete
      controller.update_path(resource)
    end
  end
end
