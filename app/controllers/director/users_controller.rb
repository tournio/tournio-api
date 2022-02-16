module Director
  class UsersController < BaseController
    NEW_ACCOUNT_PASSWORD = Rails.env.development? ? 'password' : 'bowling is great'
    NEW_USER_PARAMS = [
      :email,
      :role,
      tournament_ids: [],
    ].freeze
    UPDATE_USER_PARAMS = [
      :email,
      :role,
      :password,
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
      authorize(User)
      user = User.new(new_user_params.merge(password: NEW_ACCOUNT_PASSWORD))
      if (user.save)
        render json: UserBlueprint.render(user.reload), status: :created
      else
        render json: user.errors.full_messages, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      unauthorized
    end

    def update
      find_user
      authorize @user
      updates = updated_user_params

      # Prevent someone from updating their own role or list of associated tournaments
      if @user.identifier == current_user.identifier
        render json: {}, status: :unprocessable_entity and return if updates.has_key?(:tournament_ids) || updates.has_key?(:role)
      end
      if (@user.update(updates))
        render json: UserBlueprint.render(@user.reload), status: :ok
      else
        render json: @user.errors.full_messages, status: :unprocessable_entity
      end
    rescue Pundit::NotAuthorizedError
      unauthorized
    end

    private

    def find_user
      @user = User.find_by!(identifier: params['identifier'])
    end

    def new_user_params
      params.require(:user).permit(NEW_USER_PARAMS).to_h.with_indifferent_access
    end

    def updated_user_params
      params.require(:user).permit(UPDATE_USER_PARAMS).to_h.with_indifferent_access
    end
  end
end
