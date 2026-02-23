class CreateWebhookEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :webhook_events do |t|
      t.references :app, null: false, foreign_key: true
      t.integer :event_type, null: false
      t.string :idempotency_key_raw, null: false
      t.string :request_signature, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :received_at, null: false
      t.integer :status, null: false, default: 0
      t.string :error_code
      t.text :error_message
      t.datetime :processed_at
      t.integer :attempt_count, null: false, default: 0

      t.timestamps
    end

    add_index :webhook_events, [ :app_id, :idempotency_key_raw ], unique: true
    add_index :webhook_events, [ :app_id, :received_at ]
    add_index :webhook_events, [ :status, :received_at ]
  end
end
