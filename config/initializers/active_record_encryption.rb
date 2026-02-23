# Fallback encryption keys for local/dev use.
# Prefer credentials or ENV in real deployments.

if Rails.env.development? || Rails.env.test?
  primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
  deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
  key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]

  if primary_key.blank? || deterministic_key.blank? || key_derivation_salt.blank?
    Rails.logger.warn("[active_record_encryption] Missing ENV keys, using temporary local fallback keys")

    primary_key ||= "a" * 32
    deterministic_key ||= "b" * 32
    key_derivation_salt ||= "c" * 32
  end

  Rails.application.config.active_record.encryption.primary_key = primary_key
  Rails.application.config.active_record.encryption.deterministic_key = deterministic_key
  Rails.application.config.active_record.encryption.key_derivation_salt = key_derivation_salt
end

