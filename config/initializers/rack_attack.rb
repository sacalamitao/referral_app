class Rack::Attack
  throttle("webhook_requests_per_ip", limit: 300, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/v1/webhooks/events")
  end

  throttle("webhook_requests_per_api_key", limit: 1_000, period: 1.minute) do |req|
    next unless req.path.start_with?("/api/v1/webhooks/events")

    req.get_header("HTTP_X_API_KEY")
  end
end

Rails.application.config.middleware.use Rack::Attack

