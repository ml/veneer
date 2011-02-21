module ActiveRecord
  class Base
    module VeneerInterface
      class ClassWrapper < Veneer::Base::ClassWrapper
        def self.except_classes
          @@except_classes ||= [
            "CGI::Session::ActiveRecordStore::Session",
            "ActiveRecord::SessionStore::Session"
          ]
        end

        def self.model_classes
          klasses = ::ActiveRecord::Base.__send__(:subclasses)
          klasses.select do |klass|
            !klass.abstract_class? && !except_classes.include?(klass.name)
          end
        end

        def new(opts = {})
          ::Kernel::Veneer(klass.new(opts))
        end

        def collection_associations
          @collection_associations ||= begin
            associations = []
            [:has_many, :has_and_belongs_to_many].each do |macro|
              associations += klass.reflect_on_all_associations(macro)
            end
            associations.inject([]) do |ary, reflection|
              ary << {
                :name  => reflection.name,
                :class => reflection.class_name.constantize
              }
              ary
            end
          end
        end

        def member_associations
          @member_associations ||= begin
            associations = []
            [:belongs_to, :has_one].each do |macro|
              associations += klass.reflect_on_all_associations(macro)
            end
            associations.inject([]) do |ary, reflection|
              ary << {
                :name  => reflection.name,
                :class => reflection.class_name.constantize
              }
              ary
            end
          end
        end

        def properties
          @properties ||= begin
            klass.columns.map do |property|
              name = property.name.to_sym
             ::ActiveRecord::Base::VeneerInterface::Property.new(
                :name => name,
                :type => property.type,
                :length => property.limit,
                :primary => primary_keys.include?(name)
              )
            end
          end
        end
        
        def primary_keys
          @primary_keys ||= if ::ActiveRecord::ConnectionAdapters.const_defined?(:MysqlAdapter) && 
                               ::ActiveRecord::Base.connection.is_a?(::ActiveRecord::ConnectionAdapters::MysqlAdapter) ||
                               ::ActiveRecord::ConnectionAdapters.const_defined?(:Mysql2Adapter) && 
                               ::ActiveRecord::Base.connection.is_a?(::ActiveRecord::ConnectionAdapters::Mysql2Adapter)
                                 ::ActiveRecord::Base.connection.select_all("show indexes from active_record_bars").select { |index| 
                                   index["Key_name"] == "PRIMARY" 
                                 }.map { |index| 
                                   index["Column_name"].to_sym 
                                 }
          elsif ::ActiveRecord::ConnectionAdapters.const_defined?(:SQLiteAdapter) &&
                ::ActiveRecord::Base.connection.is_a?(::ActiveRecord::ConnectionAdapters::SQLiteAdapter) ||
                ::ActiveRecord::ConnectionAdapters.const_defined?(:SQLite3Adapter) &&
                ::ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
                  klass.connection.send(:table_structure, klass.table_name).select { |field|
                    field['pk'].to_i == 1
                  }.map { |field| field['name'].to_sym }
          end
        end

        def destroy_all
          klass.destroy_all
        end

        def find_first(opts)
          build_query(opts).first
        end

        def find_many(opts)
          build_query(opts).all
        end

        def count(opts ={})
          opts = ::Hashie::Mash.new(opts)
          build_query(opts).count
        end

        def sum(field, opts={})
          opts = ::Hashie::Mash.new(opts)
          build_query(opts).sum(field)
        end

        def max(field, opts={})
          opts = ::Hashie::Mash.new(opts)
          build_query(opts).maximum(field)
        end

        def min(field, opts={})
          opts = ::Hashie::Mash.new(opts)
          build_query(opts).minimum(field)
        end

        private
        def build_query(opts)
          query = klass
          query = query.where(opts.conditions.to_hash) if opts.conditions.present?
          query = query.limit(opts.limit.to_i)         if opts.limit?
          query = query.offset(opts.offset.to_i)       if opts.offset?
          query = query.order(opts.order)              if opts.order?
          query
        end
      end # ClassWrapper
    end
  end
end
