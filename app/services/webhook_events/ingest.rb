module WebhookEvents
  class Ingest
    SUPPORTED_EVENT_TYPES = %w[registration credit_purchase renewal].freeze

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

      reward_amount_validation = validate_reward_amount
      return reward_amount_validation if reward_amount_validation.present?

      referred_user_email_validation = validate_referred_user_email
      return referred_user_email_validation if referred_user_email_validation.present?

      referral_code_validation = validate_referral_code
      return referral_code_validation if referral_code_validation.present?

      idempotency_key = resolve_idempotency_key(event_type: event_type)
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

    def validate_reward_amount
      reward_amount = Integer(payload.fetch("reward_amount"))
      return if reward_amount.positive?

      ServiceResult.failure(error_code: "invalid_reward_amount", error_message: "reward_amount must be a positive integer", http_status: :unprocessable_entity)
    rescue KeyError
      ServiceResult.failure(error_code: "missing_reward_amount", error_message: "reward_amount is required", http_status: :unprocessable_entity)
    rescue ArgumentError, TypeError
      ServiceResult.failure(error_code: "invalid_reward_amount", error_message: "reward_amount must be a positive integer", http_status: :unprocessable_entity)
    end

    def validate_referred_user_email
      email = normalized_referred_user_email
      return if email.present?

      ServiceResult.failure(
        error_code: "missing_referred_user_email",
        error_message: "referred_user_email is required",
        http_status: :unprocessable_entity
      )
    end

    def validate_referral_code
      code = payload["referral_code"].to_s.strip
      return if code.present?

      ServiceResult.failure(
        error_code: "missing_referral_code",
        error_message: "referral_code is required",
        http_status: :unprocessable_entity
      )
    end

    def resolve_idempotency_key(event_type:)
      explicit_key = payload["idempotency_key"].to_s.strip
      return explicit_key if explicit_key.present?

      payload_fingerprint = Digest::SHA256.hexdigest(
        [
          event_type,
          payload["referral_code"].to_s.strip.upcase,
          normalized_referred_user_email,
          payload["reward_amount"].to_s.strip
        ].join("|")
      )
      "auto:#{payload_fingerprint}"
    end

    def normalized_referred_user_email
      payload["referred_user_email"].to_s.strip.downcase
    end
  end
end
