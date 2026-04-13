class AddPrimaryColorToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :primary_color, :string
  end
end
