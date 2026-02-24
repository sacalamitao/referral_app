ActiveAdmin.register RewardRule do
  permit_params :event_type, :reward_mode, :amount_cents, :percentage_bps,
                :recurrence_mode, :pending_days, :active_from, :active_to, :enabled

  index do
    selectable_column
    id_column
    column :event_type
    column :reward_mode
    column :amount_cents
    column :percentage_bps
    column :enabled
    column :created_at
    actions
  end

  filter :event_type
  filter :reward_mode
  filter :enabled
  filter :created_at
end
