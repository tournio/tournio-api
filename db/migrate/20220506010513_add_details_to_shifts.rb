class AddDetailsToShifts < ActiveRecord::Migration[7.0]
  def change
    add_column :shifts, :details, :jsonb, default: []
  end
end
