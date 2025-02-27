# Resources to manage app users.
class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  # GET /users
  def index
    authorize User

    user_scope = policy_scope(User)
      .order(:id)
      .page(params[:page])
      .includes(:agency, :user_role)

    @filter_params = filter_params

    # Search by email when query is present.
    if @filter_params[:q].present?
      user_scope = user_scope.search_by_email(@filter_params[:q])
    end

    # Filter by user state filter is present.
    if @filter_params[:aasm_state].present?
      user_scope = user_scope.send(@filter_params[:aasm_state])
    end

    @users = user_scope
  end

  # GET /users/:id
  def show
    authorize @user
  end

  # GET /users/new
  def new
    @user = User.new(agency: current_user.agency)
    authorize @user
  end

  # GET /users/:id/edit
  def edit
    authorize @user
  end

  # POST /users
  def create
    @user = User.new(agency: current_user.agency)
    authorize @user

    @user.assign_attributes(user_create_params)

    authorize @user, :assign_role?

    # Set random password and skip confirmation in favor of an invitation.
    @user.password = SecureRandom.alphanumeric(30)
    @user.skip_confirmation!

    if @user.save
      @user.invite!(current_user)
      redirect_to user_url(@user), notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/:id
  def update
    authorize @user

    @user.assign_attributes(user_update_params)

    authorize @user, :assign_role?

    if @user.save
      redirect_to user_url(@user), notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    authorize @user
    @user.destroy
    redirect_to users_url, notice: "User was successfully archived."
  end

  private

  # @return [ActionController::Parameters] permitted user filter params
  def filter_params
    params.fetch(:filter, {}).permit(:aasm_state, :q)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = policy_scope(User).find(params[:id])
  end

  # @return [ActionController::Parameters] permitted user create params
  def user_create_params
    params.require(:user).permit(
      # Pass the raw user params to the policy for dynamic evaluation
      policy(@user).permitted_create_params(params[:user])
    )
  end

  # @return [ActionController::Parameters] permitted user update params
  def user_update_params
    params.require(:user).permit(
      # Pass the raw user params to the policy for dynamic evaluation
      policy(@user).permitted_update_params(params[:user])
    )
  end
end
