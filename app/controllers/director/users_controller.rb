module Director
  class UsersController < BaseController
    def index
      authorize(User)
      @users = policy_scope(User)
      render json: UserBlueprint.render(@users), status: :ok
    end

    def show
      find_user
      authorize @user
      render json: UserBlueprint.render(@user), status: :ok
    end

    private

    def find_user
      @user = User.find_by!(identifier: params['identifier'])
    end
  end
end
