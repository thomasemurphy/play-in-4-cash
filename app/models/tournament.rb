class Tournament < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :games, dependent: :destroy

  validates :year, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def self.current
    active.order(year: :desc).first
  end
end
