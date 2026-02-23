ActiveAdmin.register User do
  permit_params :email, :status

  index do
    selectable_column
    id_column
    column :email
    column :status
    column :available_cents
    column :pending_cents
    column :total_earned_cents
    column :created_at
    actions
  end

  filter :email
  filter :status
  filter :created_at

  show do
    attributes_table do
      row :id
      row :email
      row :status
      row :available_cents
      row :pending_cents
      row :total_earned_cents
      row :created_at
      row :updated_at
    end
  end
end

