class ExistingTournamentShiftCreator
  include Sidekiq::Job

  sidekiq_options retry: false

  sidekiq_retries_exhausted do |msg, _ex|
    logger.warn "I tried to add a shift to the existing tournament, but failed. #{msg}"
  end

  attr_accessor :tournament

  def perform(tournament_id)
    self.tournament = Tournament.includes(:teams).find(tournament_id)

    create_shift
    associate_teams_with_shift
  end

  def create_shift

  end

  def associate_teams_with_shift

  end

  def try_confirming_team_shift

  end
end
