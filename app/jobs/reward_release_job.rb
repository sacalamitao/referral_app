class RewardReleaseJob < ApplicationJob
  queue_as :default

  def perform(reward_transaction_id)
    reward_transaction = RewardTransaction.find(reward_transaction_id)
    Rewards::ReleasePending.call(reward_transaction: reward_transaction)
  end
end

