module Rewards
  class ResolveRewardAmount
    def self.call(payload:)
      raw_amount = payload.fetch("reward_amount")
      reward_cents = Integer(raw_amount)

      raise ArgumentError, "reward_amount must be greater than 0" unless reward_cents.positive?

      reward_cents
    rescue KeyError
      raise ArgumentError, "reward_amount is required"
    rescue ArgumentError, TypeError
      raise ArgumentError, "reward_amount must be a positive integer"
    end
  end
end
