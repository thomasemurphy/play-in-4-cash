class AddSecondaryColorToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :secondary_color, :string
  end
end
