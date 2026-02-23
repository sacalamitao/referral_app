class CreateReferrals < ActiveRecord::Migration[7.2]
  def change
    create_table :referrals do |t|
      t.references :app, null: false, foreign_key: true
      t.references :referrer_user, null: false, foreign_key: { to_table: :users }
      t.references :referral_code, null: false, foreign_key: true
      t.string :external_user_id, null: false
      t.datetime :referred_at, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :referrals, [ :app_id, :external_user_id ], unique: true
    add_index :referrals, [ :app_id, :referrer_user_id ]
    add_index :referrals, :status
  end
end
