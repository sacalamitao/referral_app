class ConvertToSingletonArchitecture < ActiveRecord::Migration[7.2]
  def up
    create_table :system_configs do |t|
      t.string :webhook_secret, null: false
      t.string :timezone, null: false, default: "UTC"
      t.boolean :active, null: false, default: true
      t.jsonb :config, null: false, default: {}

      t.timestamps
    end

    add_index :system_configs, :active

    execute <<~SQL
      INSERT INTO system_configs (webhook_secret, timezone, active, config, created_at, updated_at)
      SELECT apps.webhook_secret, apps.timezone, (apps.status = 0), apps.config, NOW(), NOW()
      FROM apps
      ORDER BY apps.id ASC
      LIMIT 1
    SQL

    execute <<~SQL
      INSERT INTO system_configs (webhook_secret, timezone, active, config, created_at, updated_at)
      SELECT '#{SecureRandom.hex(32)}', 'UTC', true, '{}'::jsonb, NOW(), NOW()
      WHERE NOT EXISTS (SELECT 1 FROM system_configs)
    SQL

    add_index :referrals, :external_user_id, unique: true
    add_index :reward_transactions,
              [ :event_type, :external_transaction_id ],
              unique: true,
              where: "external_transaction_id IS NOT NULL",
              name: "idx_reward_txns_unique_external_event"
    add_index :idempotency_keys, :key, unique: true
    add_index :webhook_events, :idempotency_key_raw, unique: true

    remove_index :referrals, name: "index_referrals_on_app_id_and_external_user_id", if_exists: true
    remove_index :referrals, name: "index_referrals_on_app_id_and_referrer_user_id", if_exists: true
    remove_index :referrals, :app_id, if_exists: true

    remove_index :reward_rules, name: "index_reward_rules_on_app_id_and_event_type_and_enabled", if_exists: true
    remove_index :reward_rules, :app_id, if_exists: true

    remove_index :reward_transactions, name: "idx_reward_txns_unique_external_event_per_app", if_exists: true
    remove_index :reward_transactions, :app_id, if_exists: true

    remove_index :idempotency_keys, name: "index_idempotency_keys_on_app_id_and_key", if_exists: true
    remove_index :idempotency_keys, :app_id, if_exists: true

    remove_index :webhook_events, name: "index_webhook_events_on_app_id_and_idempotency_key_raw", if_exists: true
    remove_index :webhook_events, name: "index_webhook_events_on_app_id_and_received_at", if_exists: true
    remove_index :webhook_events, :app_id, if_exists: true

    remove_index :ledger_entries, name: "index_ledger_entries_on_app_id_and_occurred_at", if_exists: true
    remove_index :ledger_entries, :app_id, if_exists: true

    remove_reference :idempotency_keys, :app, foreign_key: true
    remove_reference :ledger_entries, :app, foreign_key: true
    remove_reference :referrals, :app, foreign_key: true
    remove_reference :reward_rules, :app, foreign_key: true
    remove_reference :reward_transactions, :app, foreign_key: true
    remove_reference :webhook_events, :app, foreign_key: true

    drop_table :apps
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Singleton architecture migration is irreversible"
  end
end
