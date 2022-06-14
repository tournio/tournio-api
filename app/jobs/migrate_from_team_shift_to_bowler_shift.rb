class MigrateFromTeamShiftToBowlerShift
  include Sidekiq::Job

  def perform
    # Reset each shift's requested/confirmed count to zero
    Shift.all.each do |shift|
      shift.update(requested: 0, confirmed: 0)
    end

    # Create a BowlerShift instance for each bowler in each tournament
    Tournament.all.each do |tournament|
      shift = tournament.shifts.first
      tournament.bowlers.each do |bowler|
        BowlerShift.create(shift: shift, bowler: bowler)
        TournamentRegistration.try_confirming_bowler_shift(bowler)
      end
    end
  end
end
