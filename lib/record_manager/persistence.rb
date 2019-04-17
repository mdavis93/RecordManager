require 'sqlite3'
require 'record_manager/schema'

module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  def save
    self.save! rescue false
  end

  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col|
      "#{col}=#{BlocRecord::Utility.sql_strings(
        self.instance_variable_get("@#{col}"))}"
    }.join(',')

    self.class.connection.execute <<-SQL
         UPDATE #{self.class.table}
         SET #{fields}
         WHERE id = #{self.id};
    SQL

    true
  end

  def update_attribute(attribute, value)
    self.class.update(self.id, {attribute => value})
  end

  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

  module ClassMethods
    def update_all(updates)
      update(nil, updates)
    end

    def create(attrs)
      attrs = RecordManager::Utility.convert_keys(attrs)
      attrs.delete 'id'
      vals = attributes.map do |key|
        RecordManager::Utility.sql_strings(attrs[key])
      end

      connection.execute <<-SQL
      INSERT INTO #{table} (#{attributes.join ', '})
      VALUES (#{vals.join ', '})
      SQL

      data = Hash[attributes.zip attrs.values]
      data['id'] = connection.execute('SELECT last_insert_rowid();')[0][0]
      new(data)
    end

    def update(ids, updates)
      updates = RecordManager::Utility.convert_keys(updates)
      updates.delete "id"
      updates_array = updates.map{|key, value| "#{key}=#{RecordManager::Utility.sql_strings(value)}"}
      where_clause = if ids.class == Fixnum
                       "WHERE id = #{ids};"
                     elsif ids.class == Array
                       ids.empty? ? ';' : "WHERE id IN (#{ids.join(',')});"
                     else
                       ';'
                     end
      connection.execute <<-SQL
        UPDATE #{table}
           SET #{updates_array * ','} #{where_clause}
      SQL
      true
    end
  end
end
