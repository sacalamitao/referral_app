class ServiceResult
  attr_reader :data, :error_code, :error_message, :http_status

  def initialize(success:, data: {}, error_code: nil, error_message: nil, http_status: :unprocessable_entity)
    @success = success
    @data = data
    @error_code = error_code
    @error_message = error_message
    @http_status = http_status
  end

  def success?
    @success
  end

  def self.success(data = {})
    new(success: true, data: data, http_status: :ok)
  end

  def self.failure(error_code:, error_message:, http_status: :unprocessable_entity, data: {})
    new(success: false, data: data, error_code: error_code, error_message: error_message, http_status: http_status)
  end
end

