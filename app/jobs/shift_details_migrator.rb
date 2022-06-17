class ShiftDetailsMigrator
  include Sidekiq::Job

  MAPPING = {
    'permit_solo' => 'solo',
    'permit_joins' => 'join_team',
    'permit_new_teams' => 'new_team',
  }

  def perform(shift_id)
    shift = Shift.find(shift_id)
    new_registration_types = []
    MAPPING.each_pair do |old, new|
      new_registration_types.push(new) if shift.details[old]
    end
    shift.details = { registration_types: new_registration_types }
    shift.save
  end
end
