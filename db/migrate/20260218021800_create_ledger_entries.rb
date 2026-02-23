class CreateLedgerEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :ledger_entries do |t|
      t.references :app, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :entry_type, null: false
      t.integer :account_type, null: false
      t.bigint :amount_cents, null: false
      t.string :reference_type
      t.bigint :reference_id
      t.datetime :occurred_at, null: false
      t.string :created_by_type
      t.bigint :created_by_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :ledger_entries, [ :user_id, :occurred_at ]
    add_index :ledger_entries, [ :app_id, :occurred_at ]
    add_index :ledger_entries, [ :reference_type, :reference_id ]
  end
end
