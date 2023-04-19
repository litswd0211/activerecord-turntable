module ActiveRecord::Turntable
  class Shard
    module Connections; end
    def self.connection_classes
      Connections.constants.map { |name| Connections.const_get(name) }
    end

    attr_accessor :cluster, :name

    def initialize(cluster, name = defined?(Rails) ? Rails.env : "development")
      @cluster = cluster
      @name = name
    end

    def connection_pool
      connection_klass.connection_pool
    end

    def connection
      connection_pool.connection.tap do |conn|
        conn.turntable_shard_name ||= name
      end
    end

    private

      def connection_klass
        @connection_klass ||= connection_class_instance
      end

      def connection_class_instance
        if Connections.const_defined?(name.classify)
          klass = Connections.const_get(name.classify)
        else
          klass = Class.new(ActiveRecord::Base)
          Connections.const_set(name.classify, klass)
          klass.abstract_class = true
          klass.establish_connection ActiveRecord::Base.connection_pool.spec.config[:shards][name].with_indifferent_access
        end
        klass
      end
  end
end
