# Service created to abstract this functionality from the DocumentsRequest Controller
module Users
  class FindOrCreateUserService
    def initialize(creator_user, params)
      @creator_user = creator_user
      @user_id = params[:user_id]
      @first_name = params[:first_name]
      @last_name = params[:last_name]
      @phone_number = params[:phone_number]
      @email = params[:email]
      @user_role = params[:user_role] || UserRole.client_user
      @client_id = params[:client_id]
    end

    def call
      agency = @creator_user.agency
      user = @user_id.presence ? User.where(agency: agency).find(@user_id) : User.find_or_initialize_by(email: @email)
      if user.new_record?
        user.agency = agency
        user.first_name = @first_name
        user.last_name = @last_name
        user.phone_number = @phone_number
        user.user_role = @user_role
        user.client_id = @client_id if @user_role.name == "client_user"

        user.password = SecureRandom.alphanumeric(30)
        user.skip_confirmation!

        user.invite!(@creator_user) if user.save!
      end
      user
    end
  end
end
