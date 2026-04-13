class UserPick < ApplicationRecord
  belongs_to :user
  belongs_to :game
  belongs_to :picked_winner, class_name: "Team", optional: true

  validates :user_id, uniqueness: { scope: :game_id }
end
