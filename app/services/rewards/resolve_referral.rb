module Rewards
  class ResolveReferral
    ReferralCodeNotFoundError = Class.new(StandardError)
    ReferralOwnershipMismatchError = Class.new(StandardError)

    def self.call(payload:)
      new(payload:).call
    end

    def initialize(payload:)
      @payload = payload
    end

    def call
      referral_code = resolve_referral_code
      referral = Referral.find_or_initialize_by(external_user_id: external_identity)

      if referral.new_record?
        referral.referrer_user = referral_code.user
        referral.referral_code = referral_code
        referral.referred_at = Time.current
        referral.status = :registered
        referral.metadata = referral.metadata.merge("referred_user_email" => referred_user_email)
        referral.save!
      elsif referral.referral_code_id != referral_code.id
        raise ReferralOwnershipMismatchError,
              "referred_user_email=#{referred_user_email} is already linked to referral_code=#{referral.referral_code.code}"
      end

      referral
    end

    private

    attr_reader :payload

    def resolve_referral_code
      referral_code = ReferralCode.find_by(code: normalized_referral_code, active: true)
      return referral_code if referral_code.present?

      raise ReferralCodeNotFoundError, "referral_code=#{normalized_referral_code} is invalid or inactive"
    end

    def normalized_referral_code
      payload.fetch("referral_code").to_s.strip.upcase
    end

    def referred_user_email
      payload.fetch("referred_user_email").to_s.strip.downcase
    end

    def external_identity
      "email:#{referred_user_email}"
    end
  end
end
