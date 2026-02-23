module Rewards
  class CalculateReward
    def self.call(rule:, amount_cents: nil)
      if rule.flat?
        rule.amount_cents.to_i
      else
        ((amount_cents.to_i * rule.percentage_bps.to_i) / 10_000.0).floor
      end
    end
  end
end

