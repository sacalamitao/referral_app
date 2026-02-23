class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :validatable

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      created_at
      current_sign_in_at
      current_sign_in_ip
      email
      id
      last_sign_in_at
      last_sign_in_ip
      sign_in_count
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
