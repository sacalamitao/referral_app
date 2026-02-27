class AddPaypalFieldsToCashoutRequestsAndSystemConfigs < ActiveRecord::Migration[7.2]
  def change
    change_table :cashout_requests, bulk: true do |t|
      t.integer :payout_attempts, null: false, default: 0
      t.datetime :payout_sent_at
      t.datetime :payout_failed_at
      t.string :payout_provider
      t.string :paypal_sender_batch_id
      t.string :paypal_payout_batch_id
      t.string :paypal_payout_item_id
      t.string :paypal_payout_status
      t.string :payout_last_error_code
      t.text :payout_last_error_message
      t.jsonb :payout_provider_response, null: false, default: {}
    end

    add_index :cashout_requests, :paypal_sender_batch_id, unique: true
    add_index :cashout_requests, :paypal_payout_batch_id
    add_index :cashout_requests, :paypal_payout_item_id

    change_table :system_configs, bulk: true do |t|
      t.string :paypal_client_id
      t.string :paypal_client_secret
      t.string :paypal_mode, null: false, default: "sandbox"
      t.string :paypal_payout_currency, null: false, default: "USD"
    end
  end
end
