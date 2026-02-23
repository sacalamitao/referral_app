module Idempotency
  class LockAndFetch
    Result = Struct.new(:created?, :record, :error_code, keyword_init: true)

    def self.call(app:, key:, request_hash:)
      return Result.new(created?: false, error_code: "missing_idempotency_key") if key.blank?

      record = IdempotencyKey.find_by(app: app, key: key)
      if record
        return Result.new(created?: false, record: record, error_code: (record.request_hash == request_hash ? nil : "idempotency_payload_mismatch"))
      end

      created = IdempotencyKey.create!(
        app: app,
        key: key,
        request_hash: request_hash,
        first_seen_at: Time.current,
        expires_at: 24.hours.from_now
      )

      Result.new(created?: true, record: created)
    rescue ActiveRecord::RecordNotUnique
      Result.new(created?: false, record: IdempotencyKey.find_by(app: app, key: key))
    end
  end
end

