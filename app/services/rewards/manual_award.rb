module Rewards
  class ManualAward
    SUPPORTED_EVENT_TYPES = WebhookEvent.event_types.keys.freeze

    def self.call(admin_user:, event_type:, referral_code:, referred_user_email:, reward_amount:)
      new(
        admin_user: admin_user,
        event_type: event_type,
        referral_code: referral_code,
        referred_user_email: referred_user_email,
        reward_amount: reward_amount
      ).call
    end

    def initialize(admin_user:, event_type:, referral_code:, referred_user_email:, reward_amount:)
      @admin_user = admin_user
      @event_type = event_type
      @referral_code = referral_code
      @referred_user_email = referred_user_email
      @reward_amount = reward_amount
    end

    def call
      payload = build_payload
      validation_result = validate_payload(payload)
      return validation_result unless validation_result.success?

      webhook_event = WebhookEvent.create!(
        event_type: payload.fetch("event_type"),
        status: :validated,
        idempotency_key_raw: "admin-manual:#{Time.current.to_i}:#{SecureRandom.hex(8)}",
        request_signature: "admin_manual:#{admin_user&.id || 'unknown'}",
        payload: payload,
        received_at: Time.current
      )

      WebhookEvents::Process.call(webhook_event: webhook_event)

      ServiceResult.success(webhook_event: webhook_event)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(error_code: "invalid_manual_reward", error_message: e.record.errors.full_messages.to_sentence)
    rescue StandardError => e
      ServiceResult.failure(error_code: "manual_reward_failed", error_message: e.message)
    end

    private

    attr_reader :admin_user, :event_type, :referral_code, :referred_user_email, :reward_amount

    def build_payload
      {
        "event_type" => event_type.to_s,
        "referral_code" => referral_code.to_s.strip.upcase,
        "referred_user_email" => referred_user_email.to_s.strip.downcase,
        "reward_amount" => normalized_reward_amount
      }
    end

    def validate_payload(payload)
      return ServiceResult.failure(error_code: "invalid_event_type", error_message: "event_type is not supported") unless SUPPORTED_EVENT_TYPES.include?(payload["event_type"])
      return ServiceResult.failure(error_code: "missing_referral_code", error_message: "referral_code is required") if payload["referral_code"].blank?
      return ServiceResult.failure(error_code: "missing_referred_user_email", error_message: "referred_user_email is required") if payload["referred_user_email"].blank?
      return ServiceResult.failure(error_code: "invalid_referred_user_email", error_message: "referred_user_email must be a valid email") unless payload["referred_user_email"].match?(URI::MailTo::EMAIL_REGEXP)
      return ServiceResult.failure(error_code: "invalid_reward_amount", error_message: "reward_amount must be a positive integer") if payload["reward_amount"].blank?
      return ServiceResult.failure(error_code: "invalid_reward_amount", error_message: "reward_amount must be a positive integer") unless payload["reward_amount"].positive?

      ServiceResult.success
    end

    def normalized_reward_amount
      amount = BigDecimal(reward_amount.to_s.strip)
      return nil if amount <= 0

      (amount * 100).to_i
    rescue ArgumentError, TypeError
      nil
    end
  end
end
