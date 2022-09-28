class ApplicationController < ActionController::API
  def set_time_zone
    Time.zone = tournament.timezone if tournament.present?
  end
end
