module WebhookAuth
  class VerifySignature
    MAX_DRIFT_SECONDS = 5.minutes.to_i

    Result = Struct.new(:success?, :error_code, :error_message, keyword_init: true)

    def self.call(app:, payload:, timestamp:, signature:)
      new(app:, payload:, timestamp:, signature:).call
    end

    def initialize(app:, payload:, timestamp:, signature:)
      @app = app
      @payload = payload.to_s
      @timestamp = timestamp.to_i
      @signature = signature.to_s
    end

    def call
      return Result.new(success?: false, error_code: "missing_signature", error_message: "missing signature") if signature.blank?
      return Result.new(success?: false, error_code: "expired_timestamp", error_message: "timestamp is outside allowed window") unless timestamp_fresh?

      expected = OpenSSL::HMAC.hexdigest("SHA256", app.webhook_secret, signing_payload)
      ok = ActiveSupport::SecurityUtils.secure_compare(expected, signature)

      if ok
        Result.new(success?: true)
      else
        Result.new(success?: false, error_code: "invalid_signature", error_message: "signature mismatch")
      end
    end

    private

    attr_reader :app, :payload, :timestamp, :signature

    def signing_payload
      "#{timestamp}.#{payload}"
    end

    def timestamp_fresh?
      return false if timestamp.zero?

      (Time.current.to_i - timestamp).abs <= MAX_DRIFT_SECONDS
    end
  end
end

