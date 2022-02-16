module Director
  class UsersController < BaseController
    NEW_ACCOUNT_PASSWORD = Rails.env.development? ? 'password' : 'bowling is great'
    USER_PARAMS = [
      :email,
      :role,
      tournament_ids: [],
    ].freeze

    def index
      @users = policy_scope(User)
      authorize(User)
      render json: UserBlueprint.render(@users), status: :ok
    rescue Pundit::NotAuthorizedError
      unauthorized
    end

    def show
      find_user
      authorize @user
      render json: UserBlueprint.render(@user), status: :ok
    rescue Pundit::NotAuthorizedError
      unauthorized
    end

    def create
      Rails.logger.info "**** #{request.raw_post}"

      authorize(User)
      user = User.new(user_params.merge(password: NEW_ACCOUNT_PASSWORD))
      if (user.save)
        render json: UserBlueprint.render(user.reload), status: :created
      else
        render json: user.errors.full_messages, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      unauthorized
    end

    private

    def find_user
      @user = User.find_by!(identifier: params['identifier'])
    end

    def user_params
      params.require(:user).permit(USER_PARAMS).to_h.except(:id).with_indifferent_access
    end
  end
end
