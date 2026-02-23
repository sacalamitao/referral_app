ActiveAdmin.register WebhookEvent do
  actions :index, :show

  index do
    selectable_column
    id_column
    column :app
    column :event_type
    column :status
    column :idempotency_key_raw
    column :received_at
    column :processed_at
    actions
  end

  filter :app
  filter :event_type
  filter :status
  filter :received_at

  show do
    attributes_table do
      row :id
      row :app
      row :event_type
      row :status
      row :idempotency_key_raw
      row :request_signature
      row :payload do |event|
        pre JSON.pretty_generate(event.payload)
      end
      row :error_code
      row :error_message
      row :received_at
      row :processed_at
    end
  end
end

