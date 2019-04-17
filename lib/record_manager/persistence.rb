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
      self.id = self.class.create(RecordManager::Utility.instance_variables_to_hash(self)).id
      RecordManager::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col|
      "#{col}=#{RecordManager::Utility.sql_strings(
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


  def method_missing(m, *args)
    if m.to_s.start_with?('update_')
      column_that_might_exist = m.to_s.split('update')[1]
      if self.class.columns.include?(column_that_might_exist)
        column_that_does_exist = column_that_might_exist
        self.class.update(self.id, { column_that_does_exist => args.first } )
      else
        raise "Invalid method, #{m}. Try again."
      end
    else
      super
    end
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
      if ids.class == Array
        updates_collection = []
        ids.each_with_index do |id, index|
          update(id.to_i, updates[index])
        end
      else
        updates = RecordManager::Utility.convert_keys(updates)
        updates_collection = updates.map{ |key, value| "#{key}=#{RecordManager::Utility.sql_strings(value)}" }
      end

      puts ids.class

      expression = if ids.class == Integer
                     "WHERE id = #{ids};"
                   elsif ids.class == Array
                     ids.empty? ? ';' : "WHERE id IN #{ids.join(',')};"
                   else
                     ';'
                   end

      connection.execute <<-SQL
          UPDATE #{table}
          SET #{updates_collection * ","} #{expression}
      SQL

      true
    end
  end
end
