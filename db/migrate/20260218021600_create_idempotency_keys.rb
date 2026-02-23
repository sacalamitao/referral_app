class CreateIdempotencyKeys < ActiveRecord::Migration[7.2]
  def change
    create_table :idempotency_keys do |t|
      t.references :app, null: false, foreign_key: true
      t.string :key, null: false
      t.string :request_hash, null: false
      t.integer :response_code
      t.jsonb :response_body, null: false, default: {}
      t.datetime :first_seen_at, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :idempotency_keys, [ :app_id, :key ], unique: true
    add_index :idempotency_keys, :expires_at
  end
end
