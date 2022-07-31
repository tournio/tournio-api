class ApplicationController < ActionController::API
  def set_time_zone
    Time.zone = tournament.time_zone if tournament.present?
  end
end
