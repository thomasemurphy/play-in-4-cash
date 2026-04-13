class UserPick < ApplicationRecord
  belongs_to :user
  belongs_to :game
  belongs_to :picked_winner, class_name: "Team", optional: true

  validates :user_id, uniqueness: { scope: :game_id }

  def points
    return 0 unless picked_winner_id.present? && game.winner_team_id.present?
    picked_winner_id == game.winner_team_id ? game.points_value : 0
  end

  def correct?
    game.winner_team_id.present? && picked_winner_id == game.winner_team_id
  end

  def incorrect?
    game.winner_team_id.present? && picked_winner_id.present? && picked_winner_id != game.winner_team_id
  end
end
