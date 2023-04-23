module ActiveRecord::Turntable
  module ActiveRecordExt
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :AbstractAdapter
      autoload :ConnectionHandlerExtension
      autoload :LogSubscriber
      # autoload :Persistence
      # autoload :SchemaDumper
      # autoload :Sequencer
      # autoload :Relation
      # autoload :Transactions
      autoload :AssociationPreloader
      # autoload :Association
      # autoload :LockingOptimistic
      # autoload :QueryCache
    end

    included do
      # include Transactions
      # ActiveRecord::Base.prepend(Sequencer)
      ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(AbstractAdapter)
      ActiveRecord::LogSubscriber.prepend(LogSubscriber)
      # ActiveRecord::Persistence.include(Persistence)
      # ActiveRecord::Locking::Optimistic.include(LockingOptimistic)
      # ActiveRecord::Migration.include(ActiveRecord::Turntable::Migration)
      ActiveRecord::ConnectionAdapters::ConnectionHandler.prepend(ConnectionHandlerExtension)
      ActiveRecord::Associations::Preloader::Association.prepend(AssociationPreloader)
      # ActiveRecord::Associations::Association.prepend(Association)
      # ActiveRecord::QueryCache.prepend(QueryCache)
      # require "active_record/turntable/active_record_ext/fixtures"
      # require "active_record/turntable/active_record_ext/migration_proxy"
      require "active_record/turntable/active_record_ext/activerecord_import_ext"
      # require "active_record/turntable/active_record_ext/log_subscriber"
    end
  end
end
