class CreateRewardRules < ActiveRecord::Migration[7.2]
  def change
    create_table :reward_rules do |t|
      t.references :app, null: false, foreign_key: true
      t.integer :event_type, null: false
      t.integer :reward_mode, null: false, default: 0
      t.bigint :amount_cents
      t.integer :percentage_bps
      t.integer :recurrence_mode, null: false, default: 0
      t.integer :pending_days, null: false, default: 0
      t.datetime :active_from
      t.datetime :active_to
      t.boolean :enabled, null: false, default: true
      t.jsonb :config, null: false, default: {}

      t.timestamps
    end

    add_index :reward_rules, [ :app_id, :event_type, :enabled ]
  end
end
