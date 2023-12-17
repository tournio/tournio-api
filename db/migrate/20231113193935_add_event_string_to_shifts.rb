class AddEventStringToShifts < ActiveRecord::Migration[7.0]
  def change
    add_column :shifts, :event_string, :string
    add_column :shifts, :group_title, :string
  end
end
