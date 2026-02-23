module Api
  module V1
    module Webhooks
      class EventsController < Api::V1::BaseController
        def create
          payload = JSON.parse(request.raw_post)

          result = WebhookEvents::Ingest.call(
            payload: payload,
            raw_body: request.raw_post,
            api_key: request.headers["X-Api-Key"],
            signature: request.headers["X-Signature"],
            timestamp: request.headers["X-Timestamp"]
          )

          if result.success?
            render json: {
              status: "accepted",
              event_id: result.data[:webhook_event_id],
              idempotency_key: result.data[:idempotency_key],
              replayed: result.data[:replayed]
            }, status: :accepted
          else
            render_error(code: result.error_code, message: result.error_message, status: result.http_status)
          end
        rescue JSON::ParserError
          render_error(code: "invalid_json", message: "payload must be valid JSON", status: :bad_request)
        end
      end
    end
  end
end

