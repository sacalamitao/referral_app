class DropApiKeyDigestFromApps < ActiveRecord::Migration[7.2]
  def change
    remove_index :apps, :api_key_digest, if_exists: true
    remove_column :apps, :api_key_digest, :string
  end
end
