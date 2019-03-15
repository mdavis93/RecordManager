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
        self.instance_variable_set("@#{col}", options[col])
      end
    end
  end
end