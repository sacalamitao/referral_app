module WebhookAuth
  class ResolveAppFromApiKey
    def self.call(raw_api_key:)
      return nil if raw_api_key.blank?

      App.find_by(api_key_digest: App.digest_api_key(raw_api_key))
    end
  end
end

