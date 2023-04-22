#
#= ActiveRecord::Turntable
#
# ActiveRecord Sharding Plugin
#
require "active_record/turntable/version"
require "active_record"
require "active_record/fixtures"
require "active_support/concern"
require "active_record/turntable/error"
require "logger"
require "singleton"

module ActiveRecord::Turntable
  extend ActiveSupport::Concern
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :ActiveRecordExt
    autoload :Algorithm
    autoload :Base
    autoload :Cluster
    autoload :ClusterHelperMethods
    autoload :ClusterRegistry
    autoload :Configuration
    autoload :ConfigurationMethods
    autoload :ConnectionProxy
    autoload :Compatibility
    autoload :Deprecation
    autoload :DefaultShard
    # autoload :Migration
    autoload :Mixer
    autoload :PoolProxy
    autoload :Shard
    autoload :ShardingCondition
    autoload :ShardRegistry
    autoload :Sequencer
    autoload :SequencerRegistry
  end

  included do
    include ActiveRecordExt
    include Base
    extend ConfigurationMethods
  end

  module ClassMethods
    def turntable_connection_classes
      ActiveRecord::Turntable::Shard.connection_classes
    end
  end

  require "active_record/turntable/railtie" if defined?(Rails)
end
