module WebhookAuth
  class ResolveSystemConfig
    def self.call
      SystemConfig.current
    end
  end
end
