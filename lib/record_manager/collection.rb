module RecordManager
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(num=1)
      self.any? ? self[0..num-1] : nil
    end

    def where(*args)
      ids = self.map(&:id)
      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = RecordManager::Utility.convert_keys(args.first)
          expression = expression_hash.map{ |key, value| "#{key} = #{RecordManager::Utility.sql_strings(value)}"}.join(" and ")
        end
      end

      rows = self.first.class.connection.execute <<-SQL
        SELECT #{self.first.class.attributes} FROM #{self.first.class.table} WHERE #{expression} AND id IN (#{ids})
      SQL
      rows_to_array(rows)
    end

    def not
      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = RecordManager::Utility.convert_keys(args.first)
          if args.first.keys[0] == nil
            expression = expression_hash.map{ |key, value| "#{key} IS NOT NULL" }
          else
            expression = expression_hash.map{ |key, value| "#{key} = #{RecordManager::Utility.sql_strings(value)}"}.join(" and ")
          end
        end
      end

      rows = self.first.class.connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE #{expression};
      SQL
      rows_to_array(rows)
    end
  end
end