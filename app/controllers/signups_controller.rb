class SignupsController < ApplicationController
  before_action :load_bowler
  before_action :load_signup

  PERMITTED_EVENTS = %w(request never_mind pay)

  def update
  end

  private

  attr_reader :bowler, :signup

  def load_bowler
    identifier = params.require(:bowler_identifier)
    @bowler = Bowler.includes(signups: [:purchasable_item])
                    .find_by(identifier: identifier)
  end

  def load_signup

  end

  def signup_params
    params.require(:signup).permit(:event)
  end
end
