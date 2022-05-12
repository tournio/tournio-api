class ExistingTournamentShiftCreator
  include Sidekiq::Job

  sidekiq_options retry: false

  sidekiq_retries_exhausted do |msg, _ex|
    logger.warn "I tried to add a shift to the existing tournament, but failed. #{msg}"
  end

  attr_accessor :tournament

  def perform(tournament_id)
    self.tournament = Tournament.includes(:teams).find(tournament_id)

    associate_teams_with_shift
    confirm_full_and_paid_teams
  end

  def associate_teams_with_shift
    shift = tournament.shifts.first
    tournament.teams.each do |team|
      unless team.shift.present?
        ShiftTeam.create(team: team, shift: shift)
        shift.update(requested: shift.requested + team.bowlers.count)
      end
    end
  end

  def confirm_full_and_paid_teams
    tournament.teams.reload.each do |team|
      TournamentRegistration.try_confirming_shift(team)
    end
  end
end
