# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  respond_to :json

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # Generate the token, send the email with reset instructions
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    # regardless of whether we found a user or not, respond with a 201 Created.
    # This way, we don't leak the existence (or not) of a particular address.
    render json: {}, status: :created
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # Change the password, given the presence of a valid token and new password in the parameters
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  private

  def respond_with(resource, _opts={})
    if resource.persisted? && resource.errors.empty?
      render json: UserBlueprint.render(resource), status: :ok
    else
      Rails.logger.info "------------ errors on resource: #{resource.errors.inspect}"
      render json: {error: resource.errors.full_messages.first}, status: :unprocessable_entity
    end
  end

end
