require File.join(File.dirname(__FILE__), "..", "..", "test_helper")
require 'mongo_mapper'

require 'veneer/adapters/mongomapper'

MongoMapper.connection = Mongo::Connection.new('127.0.0.1', 27017)
MongoMapper.database = 'veneer_test'

class MongoFoo
  include MongoMapper::Document
  attr_accessor :password, :password_confirmation

  key :name,          String
  key :title,         String
  key :description,   String
  key :integer_field, Integer
  key :order_field1,  Integer

  validate_on_create :check_name

  belongs_to :foo, :class_name => "MongoFoo"
  many :foos, :class_name => "MongoFoo"

  def check_name
    errors.add(:name, "may not be invalid") if name == "invalid"
  end

  def v_with_m_test
    errors.add(:name, "may not be v_with_m_test") if name == "v_with_m_test"
  end
end

class MongoMapperVeneerTest < ::Test::Unit::TestCase
  include Veneer::Lint

  def setup
    @klass              = ::MongoFoo
    @valid_attributes   = {:name => "foo", :title => "title", :description => "description", :integer_field => 1}
    @invalid_attributes = @valid_attributes.dup.merge(:name => "invalid")
  end

  def create_valid_items(num)
    attr = @valid_attributes

    (1..num).each do |i|
      MongoFoo.create(:name => "#{attr[:name]}#{i}", :title => "#{attr[:title]}#{i}", :description => "#{attr[:description]}#{i}", :integer_field => 1)
    end
  end
end




