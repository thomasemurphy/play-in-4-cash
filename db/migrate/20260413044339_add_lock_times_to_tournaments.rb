class AddLockTimesToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :east_lock_time, :datetime
    add_column :tournaments, :west_lock_time, :datetime
  end
end
