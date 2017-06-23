require 'active_record'
require 'logger'

ActiveRecord::Base.logger = Logger.new($stderr)

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.tables.include? 'masters'
    create_table :masters do |table|
      table.column :whatever,                     :string
    end
  end

  unless ActiveRecord::Base.connection.tables.include? 'slaves'
    create_table :slaves do |table|
      table.column :master_id,                    :integer
      table.column :whatever,                     :string
    end
  end
end

Object.send(:remove_const, 'Master') if Kernel.const_defined?('Master')
Object.send(:remove_const, 'Slave') if Kernel.const_defined?('Slave')

class Master < ActiveRecord::Base
  has_many :slaves, class_name: 'Slave'
end

class Slave < ActiveRecord::Base
  belongs_to :master
end
