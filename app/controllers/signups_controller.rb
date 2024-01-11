class SignupsController < ApplicationController
  wrap_parameters false

  before_action :load_bowler
  before_action :load_signup

  PERMITTED_EVENTS = %w(request never_mind pay)

  class IllegalEventError < ::RuntimeError
  end

  def update
    unless bowler.present? && signup.present?
      render json: nil, status: :not_found
      return
    end

    signup.send(convert_event_name)

    render json: SignupSerializer.new(signup).as_json, status: :ok
  rescue AASM::InvalidTransition => e
    render json: nil, status: :conflict
  rescue IllegalEventError => e
    render json: nil, status: :unprocessable_entity
  end

  private

  attr_reader :bowler, :signup, :signup_params

  def load_bowler
    identifier = params.require(:bowler_identifier)
    @bowler = Bowler.includes(signups: [:purchasable_item])
                    .find_by(identifier: identifier)
  end

  def load_signup
    if bowler.present?
      @signup = bowler.signups.find_by_identifier(signup_params[:identifier])
    end
  end

  def signup_params
    @signup_params ||= params.permit(%i(identifier event))
  end

  def convert_event_name
    raise IllegalEventError unless PERMITTED_EVENTS.include? signup_params[:event]
    "#{signup_params[:event]}!".to_sym
  end
end
