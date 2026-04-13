class AddWinnerTeamToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :winner_team_id, :integer
  end
end
