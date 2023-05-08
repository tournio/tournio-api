class CreateSendGridEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :send_grid_events, id: :string, primary_key: 'sg_event_id' do |t|
      t.string :email
      t.bigint :event_timestamp

      t.timestamps
    end
  end
end
