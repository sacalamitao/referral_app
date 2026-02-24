module WebhookEvents
  class Ingest
    SUPPORTED_EVENT_TYPES = %w[registration subscription].freeze

    def self.call(payload:, raw_body:, signature:, timestamp:)
      new(payload:, raw_body:, signature:, timestamp:).call
    end

    def initialize(payload:, raw_body:, signature:, timestamp:)
      @payload = payload
      @raw_body = raw_body
      @signature = signature
      @timestamp = timestamp
    end

    def call
      config = WebhookAuth::ResolveSystemConfig.call
      return ServiceResult.failure(error_code: "config_not_found", error_message: "system config is not configured", http_status: :service_unavailable) if config.blank?
      return ServiceResult.failure(error_code: "unauthorized", error_message: "webhook intake is inactive", http_status: :unauthorized) unless config.active?

      signature_result = WebhookAuth::VerifySignature.call(
        config: config,
        payload: raw_body,
        timestamp: timestamp,
        signature: signature
      )
      unless signature_result.success?
        return ServiceResult.failure(
          error_code: signature_result.error_code,
          error_message: signature_result.error_message,
          http_status: :unauthorized
        )
      end

      event_type = payload["event_type"].to_s
      return ServiceResult.failure(error_code: "invalid_event_type", error_message: "unsupported event_type", http_status: :unprocessable_entity) unless SUPPORTED_EVENT_TYPES.include?(event_type)

      idempotency_key = payload["idempotency_key"].to_s
      request_hash = Digest::SHA256.hexdigest(raw_body)
      idempotency = Idempotency::LockAndFetch.call(key: idempotency_key, request_hash: request_hash)

      if idempotency.error_code.present?
        return ServiceResult.failure(error_code: idempotency.error_code, error_message: "idempotency key conflict", http_status: :conflict)
      end

      existing = WebhookEvent.find_by(idempotency_key_raw: idempotency_key)
      if existing.present?
        WebhookProcessJob.perform_later(existing.id) unless existing.processed?

        return ServiceResult.success(
          webhook_event_id: existing.id,
          idempotency_key: idempotency_key,
          replayed: true
        )
      end

      event = WebhookEvent.create!(
        event_type: event_type,
        idempotency_key_raw: idempotency_key,
        request_signature: signature,
        payload: payload,
        received_at: Time.current,
        status: :validated
      )

      WebhookProcessJob.perform_later(event.id)

      ServiceResult.success(
        webhook_event_id: event.id,
        idempotency_key: idempotency_key,
        replayed: false
      )
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(error_code: "validation_error", error_message: e.record.errors.full_messages.join(", "))
    end

    private

    attr_reader :payload, :raw_body, :signature, :timestamp
  end
end
