class DropRewardRules < ActiveRecord::Migration[7.2]
  def change
    drop_table :reward_rules, if_exists: true
  end
end
