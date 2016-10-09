require "rack/body_proxy"
require "active_record/query_cache"

module ActiveRecord
  module Turntable
    module Rack
      class QueryCache < ActiveRecord::QueryCache
        def self.run
          klasses = ActiveRecord::Base.turntable_connections.values
          enables = klasses.map do |k|
            enabled = k.connection.query_cache_enabled
            k.connection.enable_query_cache!

            enabled
          end

          enables.all?
        end

        def self.complete(enabled)
          klasses =  ActiveRecord::Base.turntable_connections.values
          klasses.each do |k|
            k.connection.clear_query_cache
            k.connection.disable_query_cache! unless enabled

            unless k.connected? && k.connection.transaction_open?
              k.clear_active_connections!
            end
          end
        end

        def self.install_executor_hooks(executor = ActiveSupport::Executor)
          executor.register_hook(self)
        end
      end
    end
  end
end
