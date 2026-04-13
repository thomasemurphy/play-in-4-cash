class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :user_picks, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def display_name_or_email
    display_name.presence || email_address.split("@").first
  end

  def admin?
    admin == true
  end

  def total_points(games)
    user_picks.select { |p| games.map(&:id).include?(p.game_id) }.sum(&:points)
  end
end
