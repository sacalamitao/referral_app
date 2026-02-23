class CreateReferralCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :referral_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false
      t.boolean :active, null: false, default: true
      t.integer :format_version, null: false, default: 1

      t.timestamps
    end

    add_index :referral_codes, :code, unique: true
    add_index :referral_codes, [ :user_id, :active ], unique: true, where: "active = true"
  end
end
