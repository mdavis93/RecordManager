require 'sqlite3'

module Selection
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ','}
          FROM #{table}
         WHERE id IN (#{ids.join ','});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ', '}
        FROM #{table}
       WHERE id = #{id};
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ', '}
        FROM #{table}
       WHERE #{attribute} = #{RecordManager::Utility.sql_strings(value)};
    SQL

    rows_to_array(rows)
  end

  def take(num = 1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ','} FROM #{table}
         ORDER BY random()
         LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ','}
        FROM #{table}
       ORDER BY random()
       LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ','}
        FROM #{table}
       ORDER BY id ASC
       LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ','}
        FROM #{table}
       ORDER BY id DESC
       LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ','}
        FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = RecordManager::Utility.convert_keys(args.first)
        expression = expression_hash.map { |key, value| "#{key}=#{RecordManager::Utility.sql_strings(value)}" }.join(' and ')
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ','} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    if args.count > 1

      order_array = []

      args.each do |arg|
        arg.is_a?(String) ? order_array << arg : nil
        arg.is_a?(Symbol) ? order_array << arg.to_s : nil
        arg.is_a?(Hash) ? order_array << arg.map { |k, _v| k.to_s } : nil
      end

      if order_array.flatten.join(',').include?('desc')
        sort_type = 'desc'
        order_array.delete_at(order_array.index(sort_type))
        order = order_array.flatten.join(',') + " #{sort_type.upcase}"
      elsif order_array.flatten.join(', ').include?('asc')
        sort_type = 'asc'
        order_array.delete_at(order_array.index(sort_type))
        order = order_array.flatten.join(',') + " #{sort_type.upcase}"
      else
        order = order_array.flatten.join(',')
      end
    else
      order = args.first.to_s
    end

    rows = connection.execute <<-SQL
	       SELECT * FROM #{table}
	       ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1

      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id" }.join(' ')
      rows = connection.execute <<-SQL
	          SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
	            SELECT * FROM #{table} #{RecordManager::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
	            SELECT * FROM #{table}
	            INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        key = args.first.keys.first
        value = args.first[key]

        rows = connection.execute <<-SQL
	            SELECT * FROM #{table}
	            INNER JOIN #{key} ON #{key}.#{table}_id = #{table}.id
	            INNER JOIN #{value} ON #{value}.#{key}_id = #{key}.id
        SQL
      end
    end

    rows_to_array(rows)
  end

  private

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    collection = RecordManager::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end
end
