class RenameSessionsToNewHotspotSessions < ActiveRecord::Migration[8.0]
  def change
    rename_table :sessions, :hotspotsessions
  end
end
