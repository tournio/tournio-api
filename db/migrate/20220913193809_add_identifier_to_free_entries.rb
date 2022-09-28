class AddIdentifierToFreeEntries < ActiveRecord::Migration[7.0]
  def up
    add_column :free_entries, :identifier, :string

    FreeEntry.where(identifier: nil).each do |c|
      c.update(identifier: SecureRandom.uuid)
    end

    add_index :free_entries, :identifier, unique: true
  end

  def down
    remove_index :free_entries, :identifier
    remove_column :free_entries, :identifier
  end

end
