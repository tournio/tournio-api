class AddNotificationPreferenceToContacts < ActiveRecord::Migration[7.0]
  def change
    change_table :contacts do |t|
      t.integer :notification_preference, default: 0
    end
  end
end
