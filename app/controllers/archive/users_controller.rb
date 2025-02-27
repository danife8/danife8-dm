# Resources to manage archived app users.
class Archive::UsersController < ApplicationController
  before_action :set_user, only: %i[update]

  # GET /archive/users
  def index
    authorize User

    user_scope = policy_scope(User)
      .only_deleted
      .order(:id)
      .page(params[:page])
      .includes(:agency, :user_role)

    # Search by email when query is present.
    @filter_params = filter_params
    if @filter_params[:q].present?
      user_scope = user_scope.search_by_email(@filter_params[:q])
    end

    @users = user_scope
  end

  # PATCH/PUT /archive/users/:id
  def update
    authorize @user
    if @user.recover
      redirect_to user_url(@user), notice: "User was successfully restored."
    else
      redirect_to archive_users_url, notice: "There was a problem restoring the user."
    end
  end

  private

  # @return [ActionController::Parameters] permitted user filter params
  def filter_params
    params.fetch(:filter, {}).permit(:q)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = policy_scope(User).only_deleted.find(params[:id])
  end
end
