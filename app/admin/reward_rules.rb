ActiveAdmin.register RewardRule do
  permit_params :app_id, :event_type, :reward_mode, :amount_cents, :percentage_bps,
                :recurrence_mode, :pending_days, :active_from, :active_to, :enabled

  index do
    selectable_column
    id_column
    column :app
    column :event_type
    column :reward_mode
    column :amount_cents
    column :percentage_bps
    column :enabled
    column :created_at
    actions
  end

  filter :app
  filter :event_type
  filter :reward_mode
  filter :enabled
  filter :created_at
end

