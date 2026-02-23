class CreateCashoutRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :cashout_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.integer :status, null: false, default: 0
      t.string :payout_method
      t.string :payout_reference
      t.references :reviewed_by_admin_user, null: true, foreign_key: { to_table: :admin_users }
      t.datetime :reviewed_at
      t.datetime :paid_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :cashout_requests, [ :user_id, :status, :created_at ]
    add_index :cashout_requests, [ :status, :created_at ]
  end
end
