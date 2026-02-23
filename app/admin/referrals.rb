ActiveAdmin.register Referral do
  actions :index, :show

  index do
    selectable_column
    id_column
    column :app
    column :referrer_user
    column :external_user_id
    column :status
    column :referred_at
    actions
  end

  filter :app
  filter :referrer_user
  filter :status
  filter :external_user_id
end

