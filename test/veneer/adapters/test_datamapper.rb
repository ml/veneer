require File.join(File.dirname(__FILE__), "..", "..", "test_helper")
require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'veneer/adapters/datamapper'

DataMapper.setup(:default, 'sqlite3::memory:')

class DMFoo
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String
  property :title,        String
  property :description,  String
  property :order_field1, Integer

  validates_with_method :name, :method => :check_name

  def check_name
    if name == "invalid"
      [false, "Invalid name"]
    else
      true
    end
  end

  def v_with_m_test
    if name == "v_with_m_test"
      [false, "name cannot be v_with_m_test"]
    else
      true
    end
  end
end

DataMapper.auto_migrate!

class DataMapperVeneerTest < ::Test::Unit::TestCase
  include Veneer::Lint

  def setup
    @klass              = ::DMFoo
    @valid_attributes   = {:name => "foo", :title => "title", :description => "description"}
    @invalid_attributes = @valid_attributes.dup.merge(:name => "invalid")
  end

  def create_valid_items(num)
    attr = @valid_attributes

    (1..num).each do |i|
      DMFoo.create(:name => "#{attr[:name]}#{i}", :title => "#{attr[:title]}#{i}", :description => "#{attr[:description]}#{i}")
    end
  end
end

