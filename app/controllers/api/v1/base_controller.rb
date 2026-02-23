module Api
  module V1
    class BaseController < ActionController::API
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def render_success(data = {}, status: :ok)
        render json: { status: "ok", data: data }, status: status
      end

      def render_error(code:, message:, status: :unprocessable_entity)
        render json: { status: "error", code: code, message: message }, status: status
      end

      def render_bad_request(exception)
        render_error(code: "bad_request", message: exception.message, status: :bad_request)
      end
    end
  end
end

