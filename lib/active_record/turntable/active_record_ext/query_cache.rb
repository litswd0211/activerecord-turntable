module ActiveRecord::Turntable
  module ActiveRecordExt
    module QueryCache
      def self.prepended(klass)
        class << klass
          prepend ClassMethods.compatible_module
        end
      end

      module ClassMethods
        extend Compatibility

        module V6_0
        end

        module V5_2
        end

        module
          def run
            result = super

            pools = ActiveRecord::Base.turntable_pool_list
            pools.each do |k|
              k.connection.enable_query_cache!
            end

            result
          end

          def complete(state)
            enabled, _connection_id = state
            super

            klasses = ActiveRecord::Base.turntable_pool_list
            klasses.each do |k|
              k.connection.clear_query_cache
              k.connection.disable_query_cache! unless enabled
            end
          end
        end
      end
    end
  end
end
