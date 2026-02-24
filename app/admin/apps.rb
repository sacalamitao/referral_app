ActiveAdmin.register App do
  permit_params :name, :status, :timezone, :webhook_secret

  member_action :reveal_api_key, method: :get do
    @app = resource
    @raw_api_key = session.delete(:new_app_api_key)

    if @raw_api_key.blank?
      redirect_to resource_path(@app), alert: "API key can only be shown once. Rotate the key to get a new one."
      return
    end

    render "admin/apps/reveal_api_key"
  end

  member_action :rotate_api_key, method: :post do
    app = resource
    session[:new_app_api_key] = app.rotate_api_key!
    redirect_to reveal_api_key_admin_app_path(app), notice: "API key rotated. Save it now; it will only be shown once."
  end

  action_item :rotate_api_key, only: :show do
    link_to "Rotate API Key", rotate_api_key_admin_app_path(resource),
            method: :post,
            data: { confirm: "Rotate API key now? Existing integrations using the old key will stop working." }
  end

  controller do
    def create
      super do |success, _failure|
        success.html do
          session[:new_app_api_key] = resource.raw_api_key
          redirect_to reveal_api_key_admin_app_path(resource)
        end
      end
    end
  end

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
