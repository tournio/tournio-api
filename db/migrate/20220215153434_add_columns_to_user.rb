class AddColumnsToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string :identifier
      t.integer :role, default: 0, null: false
    end

    User.all.each { |user| user.update_column(:identifier, SecureRandom.uuid) }

    add_index :users, :identifier, unique: true
  end
end
