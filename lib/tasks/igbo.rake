namespace :igbo do
  desc "Called by a scheduler, to send daily registration summaries to secretaries of active tournaments"
  task send_registration_summaries: :environment do
    puts "Environment: #{Rails.env}"
    puts "Preparing to send registration summaries"
    Tournament.includes(:contacts).active.each do |tournament|
      puts "-- Tournament: #{tournament.name}"
      tournament.contacts.registration_notifiable.each do |contact|
        puts "---- Sending to #{contact.role}"
        if Rails.env.production?
          RecentRegistrationsSummaryJob.perform_async(tournament.id, contact.email)
        else
          RecentRegistrationsSummaryJob.perform_async(tournament.id)
        end
      end
      puts "-- Finished with tournament"
    end
    puts "Finished sending registration summaries."
  end

  desc "Called by a scheduler, to send daily payment summaries to treasurers of active tournaments"
  task send_payment_summaries: :environment do
    puts "Environment: #{Rails.env}"
    puts "Preparing to send payment summaries"
    Tournament.includes(:contacts).active.each do |tournament|
      puts "-- Tournament: #{tournament.name}"
      tournament.contacts.payment_notifiable.each do |contact|
        puts "---- Sending to #{contact.role}"
        if Rails.env.production?
          RecentPaymentsSummaryJob.perform_async(tournament.id, contact.email)
        else
          RecentPaymentsSummaryJob.perform_async(tournament.id)
        end
      end
      puts "-- Finished with tournament"
    end
    puts "Finished sending payment summaries."
  end
end
