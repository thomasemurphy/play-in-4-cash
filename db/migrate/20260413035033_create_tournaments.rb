class CreateTournaments < ActiveRecord::Migration[8.1]
  def change
    create_table :tournaments do |t|
      t.integer :year
      t.boolean :active

      t.timestamps
    end
    add_index :tournaments, :year, unique: true
  end
end
