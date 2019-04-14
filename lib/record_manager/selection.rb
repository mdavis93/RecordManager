require 'sqlite3'
require_relative 'selection_dynamic_finder'

module Selection
  def find(*ids)
    # Validate 'ids' Array
    if ids.length == 1
      find_one(ids.first)
    else
      begin
        unless ids.all?(&method(:valid_number?))
          raise ArgumentError, "Invalid Argument for 'find'. All IDs must be numeric values above '0'."
        end
        rows = connection.execute <<-SQL
        SELECT #{columns.join ','}
          FROM #{table}
         WHERE id IN (#{ids.join ','});
        SQL

        rows_to_array(rows)
      rescue ArgumentError
        # TODO: Inform API caller of invalid request
        puts 'ArgumentError Caught'
      end
    end
  end

  def find_one(id)
    raise ArgumentError, "Invalid Argument for 'find_one'. 'id' must be numeric values above '0'." unless valid_number?(id)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ', '}
        FROM #{table}
       WHERE id = #{id};
    SQL
    init_object_from_row(row)
  rescue ArgumentError
    # TODO: Inform API caller of invalid request
    puts 'ArgumentError Caught'
  end

  def find_by(attribute, value)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ', '}
        FROM #{table}
       WHERE #{attribute} = #{RecordManager::Utility.sql_strings(value)};
    SQL

    rows_to_array(rows)
  end

  def find_each(options = {})
    puts '\'find_each\' Called'
    rows = retrieve_records(options)

    rows.each do |row|
      row = init_object_from_row(row)
      yield(row) if block_given?
    end
  end

  def find_in_batches(options = {})
    rows = rows_to_array(retrieve_records(options))
    yield(rows) if block_given?
  end

  def take(num = 1)
    raise ArgumentError, "Invalid Argument for 'take'. 'num' must be a numeric value above '0'."  unless valid_number?(num)
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
  rescue ArgumentError
    # TODO: Inform API caller of invalid input
    puts 'ArgumentError Caught'
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
        FROM #{table}
    SQL

    rows_to_array(rows)
  end

  def self.method_missing(method, *args, &bloc)
    match = SelectionDynamicFinder.new(method)
    if match.match?
      define_dynamic_finder(method, match.attribute)
      send(method, args.first)
    else
      super
    end
  end

  def self.define_dynamic_finder(finder, attribute)
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def self.#{finder}(#{attribute})
        find(#{attribute}: #{attribute})
      end
    RUBY
  end

  def self.respond_to_missing?(method, include_private = false)
    if SelectionDynamicFinder.new(method).match?
      true
    else
      super
    end
  end

  private

  def valid_number?(input)
    res = true
    if input.is_a?(Array)
      input.each do |val|
        res = val.to_s.to_i == val if res
      end
    else
      res = input.to_s.to_i == input
    end
    res
  end

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end

  def retrieve_records(options)
    start = options.has_key?(:start) ? options[:start] : nil
    batch_size = options.has_key?(:batch_size) ? options[:batch_size] : nil
    rows = nil

    if start && batch_size
      rows = retrieve_with_limit_offset(batch_size, start)
    elsif start && batch_size.nil?
      rows = retrieve_with_offset(start)
    elsif start.nil? && batch_size
      rows = retrieve_with_limit(batch_size)
    else
      puts 'neither'
      rows = connection.execute <<-SQL
        SELECT #{columns.join ','} FROM #{table};
      SQL
    end
    rows
  end

  def retrieve_with_limit_offset(limit, offset)
    puts 'start and batch size found'
    rows = connection.execute <<-SQL
        SELECT #{columns.join ','} FROM #{table}
        LIMIT #{limit} OFFSET #{offset};
    SQL
    rows
  end

  def retrieve_with_limit(limit)
    puts 'no start but batch size'
    rows = connection.execute <<-SQL
        SELECT #{columns.join ','} FROM #{table}
        LIMIT #{limit};
    SQL
    rows
  end

  def retrieve_with_offset(offset)
    puts 'start but no batch size'
    rows = connection.execute <<-SQL
        SELECT #{columns.join ','} FROM #{table}
        OFFSET #{offset};
    SQL
    rows
  end
end