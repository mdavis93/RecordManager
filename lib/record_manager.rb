module RecordManager
  def self.connect_to(filename, db_dialect)
    @database_filename = filename
    @database_platform = db_dialect
  end

  def self.database_filename
    @database_filename
  end

  def self.database_platform
    @database_platform
  end
end