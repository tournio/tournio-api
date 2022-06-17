class MigrateShiftDetailsJob
  include Sidekiq::Job

  def perform
    Shift.all.each do |s|
      ShiftDetailsMigrator.perform_async(s.id)
    end
  end
end
