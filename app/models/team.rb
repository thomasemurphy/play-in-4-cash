class Team < ApplicationRecord
  belongs_to :tournament

  validates :name, presence: true
  validates :abbreviation, presence: true
  validates :conference, presence: true, inclusion: { in: %w[East West] }
  validates :seed, presence: true, inclusion: { in: 7..10 }

  scope :east, -> { where(conference: "East") }
  scope :west, -> { where(conference: "West") }
  scope :for_conference, ->(conf) { where(conference: conf) }
  scope :by_seed, -> { order(:seed) }
end
