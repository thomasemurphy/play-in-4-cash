class Tournament < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :games, dependent: :destroy

  validates :year, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def self.current
    active.order(year: :desc).first
  end

  def lock_time_for(conference)
    conference == "East" ? east_lock_time : west_lock_time
  end

  def locked_for?(conference)
    lock_time = lock_time_for(conference)
    lock_time.present? && Time.current >= lock_time
  end
end
