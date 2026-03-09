module Cashouts
  class ParseUsdAmount
    InvalidAmountError = Class.new(StandardError)

    USD_FORMAT = /\A\d+(\.\d{1,2})?\z/.freeze

    def self.call(raw_amount:)
      new(raw_amount:).call
    end

    def initialize(raw_amount:)
      @raw_amount = raw_amount
    end

    def call
      value = raw_amount.to_s.strip
      raise InvalidAmountError, invalid_amount_message if value.blank?
      raise InvalidAmountError, invalid_amount_message unless USD_FORMAT.match?(value)

      amount_cents = (BigDecimal(value) * 100).to_i
      raise InvalidAmountError, invalid_amount_message unless amount_cents.positive?

      amount_cents
    end

    private

    attr_reader :raw_amount

    def invalid_amount_message
      "Amount must be a valid USD value like 20, 0.20, or 20.20"
    end
  end
end
