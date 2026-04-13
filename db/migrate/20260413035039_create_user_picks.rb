class CreateUserPicks < ActiveRecord::Migration[8.1]
  def change
    create_table :user_picks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.references :picked_winner, null: true, foreign_key: { to_table: :teams }

      t.timestamps
    end
    add_index :user_picks, [:user_id, :game_id], unique: true
  end
end
