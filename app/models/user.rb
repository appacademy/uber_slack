# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  email      :string           not null
#  first_name :string
#  last_name  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ActiveRecord::Base
  validates :email,
            presence: true,
            uniqueness: true,
            format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }

  validates_presence_of :password_digest, message: 'You must set the password'
  validates_presence_of :session_token

  after_initialize :ensure_session_token
  before_save -> { email.downcase! }

  def self.generate_session_token
    SecureRandom::urlsafe_base64(16)
  end

  def reset_session_token!
    self.session_token = self.class.generate_session_token
    self.save!
    self.session_token
  end

  def password=(password)
    self.password_digest = BCrypt::Password.create(password)
  end

  def is_password?(password)
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end

  def invite_to_slack
    SlackClient.invite(email, first_name)
  end

  private

  def ensure_session_token
    self.session_token ||= self.class.generate_session_token
  end
end
