require 'record_manager/utility'
require 'record_manager/schema'
require 'record_manager/persistence'
require 'record_manager/selection'
require 'record_manager/connection'

module RecordManager
  class Base
    include Persistence
    extend Selection
    extend Schema
    extend Connection

    def initialize(options = {})
      options = RecordManager::Utility.convert_keys(options)

      self.class.columns.each do |col|
        self.class.send(:attr_accessor, col)
        instance_variable_set("@#{col}", options[col])
      end
    end

    def self.method_missing( method, *args, &block )
      if method.to_s =~ /^find_by_(.*)$/
        find_by(Regexp.last_match[1], args.first)
      else
        super
      end
    end

    def self.respond_to_missing?( method, include_private = false)
      if method.to_s =~ /^find_by_(.*)$/
        true
      else
        super
      end
    end

  end
end