ActiveAdmin.register SystemConfig do
  actions :all, except: [ :destroy ]
  permit_params :webhook_secret, :timezone, :active, :config

  action_item :new, only: :index, if: proc { SystemConfig.count.zero? } do
    link_to "New System Config", new_resource_path
  end

  action_item :new, only: :show, if: proc { false }

  index do
    selectable_column
    id_column
    column :active
    column :timezone
    column :created_at
    column :updated_at
    actions
  end

  filter :active
  filter :timezone
  filter :created_at

  form do |f|
    f.inputs do
      f.input :active
      f.input :timezone
      f.input :webhook_secret
      f.input :config
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :active
      row :timezone
      row :config
      row :created_at
      row :updated_at
    end
  end

  controller do
    def create
      if SystemConfig.exists?
        redirect_to admin_system_configs_path, alert: "Only one system config is allowed"
        return
      end

      super
    end
  end
end
