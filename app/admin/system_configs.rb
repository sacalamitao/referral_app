ActiveAdmin.register SystemConfig do
  actions :all, except: [ :destroy ]
  permit_params :webhook_secret, :timezone, :active, :config, :paypal_client_id, :paypal_client_secret, :paypal_mode, :paypal_payout_currency

  action_item :new, only: :index, if: proc { SystemConfig.count.zero? } do
    link_to "New System Config", new_resource_path
  end

  action_item :new, only: :show, if: proc { false }

  index do
    selectable_column
    id_column
    column :active
    column :timezone
    column :paypal_mode
    column :paypal_payout_currency
    column :created_at
    column :updated_at
    actions
  end

  filter :active
  filter :timezone
  filter :paypal_mode
  filter :created_at

  form do |f|
    f.inputs do
      f.input :active
      f.input :timezone
      f.input :webhook_secret
      f.input :paypal_client_id
      f.input :paypal_client_secret
      f.input :paypal_mode, as: :select, collection: %w[sandbox live], include_blank: false
      f.input :paypal_payout_currency
      f.input :config
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :active
      row :timezone
      row :paypal_mode
      row :paypal_payout_currency
      row(:paypal_client_id) { resource.paypal_client_id.present? ? "configured" : "not configured" }
      row(:paypal_client_secret) { resource.paypal_client_secret.present? ? "configured" : "not configured" }
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
