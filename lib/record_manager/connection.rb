require 'sqlite3'
require 'pg'

module Connection
  def connection
    if RecordManager.database_platform == :sqlite3
      @connection ||= SQLite3::Database.new(RecordManager.database_filename)
    elsif RecordManager.database_platform == :pg
      @connection ||= PG::Connection.new(dbname: RecordManager.database_filename)
    end
  end
end