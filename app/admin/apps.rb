ActiveAdmin.register App do
  permit_params :name, :status, :timezone, :webhook_secret

  index do
    selectable_column
    id_column
    column :name
    column :status
    column :timezone
    column :created_at
    actions
  end

  filter :name
  filter :status
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :status
      f.input :timezone
      f.input :webhook_secret
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :status
      row :timezone
      row :api_key_digest
      row :created_at
      row :updated_at
    end
  end
end

