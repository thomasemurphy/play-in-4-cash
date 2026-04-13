class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :abbreviation
      t.string :conference
      t.integer :seed
      t.references :tournament, null: false, foreign_key: true

      t.timestamps
    end
  end
end
