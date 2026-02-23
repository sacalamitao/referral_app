class ReferralCode < ApplicationRecord
  CODE_LENGTH = 8

  belongs_to :user
  has_many :referrals, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :format_version, numericality: { only_integer: true, greater_than: 0 }

  before_validation :assign_code!, on: :create

  private

  def assign_code!
    return if code.present?

    self.code = loop do
      candidate = SecureRandom.alphanumeric(CODE_LENGTH).upcase
      break candidate unless self.class.exists?(code: candidate)
    end
  end
end

