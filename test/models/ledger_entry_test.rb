require "test_helper"

class LedgerEntryTest < ActiveSupport::TestCase
  test "reward helpers return reward source and referred user email for reward transaction references" do
    reward_txn = RewardTransaction.new(
      event_type: :subscription,
      metadata: { "referred_user_email" => "  invitee@example.com  " }
    )

    ledger_entry = LedgerEntry.new(reference: reward_txn)

    assert_equal "subscription", ledger_entry.reward_source
    assert_equal "invitee@example.com", ledger_entry.referred_user_email
  end

  test "reward helpers return nil for non reward references" do
    cashout_request = CashoutRequest.new
    ledger_entry = LedgerEntry.new(reference: cashout_request)

    assert_nil ledger_entry.reward_source
    assert_nil ledger_entry.referred_user_email
  end
end

