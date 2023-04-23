module ActiveRecord::Turntable
  module ActiveRecordExt
    module ConnectionHandlerExtension
      def owner_to_turntable_pool
        @owner_to_turntable_pool ||= Concurrent::Map.new(initial_capacity: 2)
      end

      # @note Override not to establish_connection destroy existing connection pool proxy object
      def retrieve_connection_pool(connection_name, role: ActiveRecord::Base.current_role, shard: ActiveRecord::Base.current_shard)
        # puts "@@@@@@@@ retrieve_connection_pool : #{connection_name}"
        ConnectionPoolProxyV2.new(self, super)
        #owner_to_turntable_pool.fetch(connection_name) do
        #  super
        #end
      end

      class ConnectionPoolProxyV2
        def initialize(connection_handler, raw_conn_pool)
          #@connection_handler = connection_handler
          #@connection_name = connection_name
          #@shard = shard
          #@role = role
          @raw_conn_pool = raw_conn_pool
          @conn_proxy = ConnectionProxyV2.new(self, raw_conn_pool.connection)
        end

        def connection
          @conn_proxy
        end

        def method_missing(method, *args, &block)
          puts "@@@@@@@@ ConnectionPoolProxyV2#method_missing : #{method}"
          #puts @pool
          @raw_conn_pool.public_send(method, *args, &block)
        end
      end

      class ConnectionProxyV2
        include ConnectionProxy::Mixable

        def initialize(conn_pool_proxy, raw_conn)
          #@conn_pool_proxy = conn_pool_proxy
          @raw_conn = raw_conn
        end

        def method_missing(method, *args, &block)
          mixable = mixable?(method, *args)
          puts "@@@@@@@@ ConnectionProxyV2#method_missing : #{method} : MIX=#{mixable}"
          @raw_conn.public_send(method, *args, &block)
        end
      end
    end
  end
end
