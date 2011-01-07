module MongoMapper
  module Document
    module VeneerInterface
      class ClassWrapper < Veneer::Base::ClassWrapper
        def new(opts = {})
          ::Kernel::Veneer(klass.new(opts))
        end

        def destroy_all
          klass.destroy_all
        end

        def find_first(opts)
          klass.first(opts)
        end

        def find_many(opts)
          klass.all(opts)
        end
      end
    end
  end
end
