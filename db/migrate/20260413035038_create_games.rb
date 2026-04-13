class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.references :tournament, null: false, foreign_key: true
      t.string :conference
      t.string :game_type
      t.references :home_team, null: false, foreign_key: { to_table: :teams }
      t.references :away_team, null: false, foreign_key: { to_table: :teams }

      t.timestamps
    end
  end
end
