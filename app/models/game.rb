class Game < ApplicationRecord
  belongs_to :tournament
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  belongs_to :winner_team, class_name: "Team", optional: true

  SEVEN_EIGHT = "seven_eight"
  NINE_TEN    = "nine_ten"
  FINAL       = "final"

  POINTS = { SEVEN_EIGHT => 2, NINE_TEN => 2, FINAL => 3 }.freeze

  validates :conference, presence: true, inclusion: { in: %w[East West] }
  validates :game_type, presence: true, inclusion: { in: %w[seven_eight nine_ten final] }

  def points_value
    POINTS[game_type]
  end

  def display_name
    case game_type
    when SEVEN_EIGHT then "#{conference} #7 vs #8"
    when NINE_TEN    then "#{conference} #9 vs #10"
    when FINAL       then "#{conference} Play-In Final"
    end
  end

  def result_description
    case game_type
    when SEVEN_EIGHT then "Winner earns #{conference} #7 seed"
    when NINE_TEN    then "Winner advances to Play-In Final"
    when FINAL       then "Winner earns #{conference} #8 seed"
    end
  end
end
