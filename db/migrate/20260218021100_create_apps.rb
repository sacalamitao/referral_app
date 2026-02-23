class CreateApps < ActiveRecord::Migration[7.2]
  def change
    create_table :apps do |t|
      t.string :name, null: false
      t.string :api_key_digest, null: false
      t.string :webhook_secret, null: false
      t.integer :status, null: false, default: 0
      t.string :timezone, null: false, default: "UTC"
      t.jsonb :config, null: false, default: {}

      t.timestamps
    end

    add_index :apps, :name, unique: true
    add_index :apps, :api_key_digest, unique: true
    add_index :apps, :status
  end
end
