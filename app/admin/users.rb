ActiveAdmin.register User do
  permit_params :email, :status

  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column :date_of_birth
    column :status
    column :available_cents
    column :pending_cents
    column :total_earned_cents
    column :created_at
    actions
  end

  filter :email
  filter :first_name
  filter :last_name
  filter :date_of_birth
  filter :status
  filter :created_at

  show do
    attributes_table do
      row :id
      row :email
      row :first_name
      row :last_name
      row :contact_number
      row :address_line1
      row :address_line2
      row :city
      row :province_code
      row :postal_code
      row :country_code
      row :residential_address
      row :date_of_birth
      row(:sin) { |user| user.masked_sin }
      row :status
      row :available_cents
      row :pending_cents
      row :total_earned_cents
      row :created_at
      row :updated_at
    end
  end
end
