require 'sqlite3'

module Connection
  def connection
    @connection ||= SQLite3::Database.new(RecordManager.database_filename)
  end
end