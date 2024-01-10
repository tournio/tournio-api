class SignupsController < ApplicationController
  wrap_parameters false
  before_action :load_bowler
  before_action :load_signup

  PERMITTED_EVENTS = %w(request never_mind pay)

  class UnpermittedEventError < ::RuntimeError
  end

  def update
    signup.send(convert_event_name)
  rescue UnpermittedEventError => e
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
    @signup = bowler.signups.find_by_identifier(signup_params[:identifier])
  end

  def signup_params
    @signup_params ||= params.require(%i(identifier event))
  end

  def convert_event_name
    raise UnpermittedEventError unless PERMITTED_EVENTS.include? signup_params[:event]
    "#{signup_params[:event]}!".to_sym
  end
end
