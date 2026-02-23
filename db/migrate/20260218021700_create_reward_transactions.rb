class CreateRewardTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :reward_transactions do |t|
      t.references :app, null: false, foreign_key: true
      t.references :referral, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :source_event, null: true, foreign_key: { to_table: :webhook_events }

      t.integer :event_type, null: false
      t.string :external_transaction_id
      t.string :idempotency_fingerprint, null: false
      t.bigint :gross_cents, null: false, default: 0
      t.bigint :reward_cents, null: false
      t.integer :status, null: false, default: 0
      t.datetime :available_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :reward_transactions, :idempotency_fingerprint, unique: true
    add_index :reward_transactions,
      [ :app_id, :event_type, :external_transaction_id ],
      unique: true,
      where: "external_transaction_id IS NOT NULL",
      name: "idx_reward_txns_unique_external_event_per_app"
    add_index :reward_transactions, [ :user_id, :status, :available_at ]
  end
end
