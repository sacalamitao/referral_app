class User < ApplicationRecord
  PROFILE_ATTRIBUTE_KEYS = %i[
    first_name
    last_name
    contact_number
    address_line1
    address_line2
    city
    province_code
    postal_code
    country_code
    date_of_birth
    sin
  ].freeze

  SIN_SANITIZER_REGEX = /[^\d]/.freeze
  SIN_FORMAT_REGEX = /\A\d{9}\z/.freeze
  CANADIAN_POSTAL_CODE_REGEX = /\A[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z][ -]?\d[ABCEGHJ-NPRSTV-Z]\d\z/i.freeze
  CANADIAN_PROVINCE_CODES = %w[
    AB BC MB NB NL NS NT NU ON PE QC SK YT
  ].freeze

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  encrypts :sin

  enum :status, { active: 0, suspended: 1 }, default: :active

  has_many :referral_codes, dependent: :destroy
  has_one :active_referral_code, -> { where(active: true) }, class_name: "ReferralCode", inverse_of: :user
  has_many :referrals_as_referrer, class_name: "Referral", foreign_key: :referrer_user_id, inverse_of: :referrer_user, dependent: :restrict_with_error
  has_many :reward_transactions, dependent: :restrict_with_error
  has_many :ledger_entries, dependent: :restrict_with_error
  has_many :cashout_requests, dependent: :restrict_with_error

  validates :available_cents, :pending_cents, :total_earned_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :first_name, :last_name, presence: true
  validates :contact_number, presence: true,
                             length: { minimum: 7, maximum: 20 },
                             format: { with: /\A[\d\s\-\+\(\)]+\z/, message: "is invalid" }
  validates :address_line1, :city, :province_code, :postal_code, :country_code, :date_of_birth, :sin, presence: true
  validates :province_code, inclusion: { in: CANADIAN_PROVINCE_CODES, message: "must be a valid Canadian province/territory code" }
  validates :country_code, inclusion: { in: [ "CA" ], message: "must be CA" }
  validates :postal_code, format: { with: CANADIAN_POSTAL_CODE_REGEX, message: "must be a valid Canadian postal code" }
  validates :sin, format: { with: SIN_FORMAT_REGEX, message: "must be 9 digits" }

  before_validation :normalize_sin
  before_validation :normalize_address_fields
  before_validation :sync_residential_address
  after_create :ensure_active_referral_code!

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      address_line1
      address_line2
      available_cents
      city
      contact_number
      country_code
      created_at
      current_sign_in_at
      current_sign_in_ip
      date_of_birth
      email
      first_name
      id
      last_sign_in_at
      last_sign_in_ip
      last_name
      pending_cents
      postal_code
      province_code
      sign_in_count
      status
      total_earned_cents
      updated_at
    ]
  end

  def masked_sin
    return nil if sin.blank?

    "*****#{sin.last(4)}"
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[
      cashout_requests
      ledger_entries
      referral_codes
      referrals_as_referrer
      reward_transactions
    ]
  end

  private

  def normalize_sin
    self.sin = sin.to_s.gsub(SIN_SANITIZER_REGEX, "").presence
  end

  def normalize_address_fields
    self.province_code = province_code.to_s.upcase.presence
    self.country_code = country_code.to_s.upcase.presence || "CA"
    self.postal_code = normalize_postal_code(postal_code)
  end

  def normalize_postal_code(value)
    compacted = value.to_s.upcase.gsub(/\s+/, "").presence
    return nil if compacted.blank?

    return compacted unless compacted.match?(/\A[A-Z]\d[A-Z]\d[A-Z]\d\z/)

    "#{compacted[0..2]} #{compacted[3..5]}"
  end

  def sync_residential_address
    self.residential_address = [
      address_line1,
      address_line2,
      [ city, province_code, postal_code ].compact_blank.join(", "),
      country_code
    ].compact_blank.join("\n").presence
  end

  def ensure_active_referral_code!
    referral_codes.create!(active: true) unless active_referral_code
  end
end
