module ActiveRecord::Turntable
  module ActiveRecordExt
    module Transactions
      # @note Override to start transaction on current shard
      def with_transaction_returning_status
        klass = self.class
        return super unless klass.turntable_enabled?

        status = nil
        if self.new_record? && self.turntable_shard_key.to_s == klass.primary_key &&
            self.id.nil? && klass.prefetch_primary_key?
          self.id = klass.next_sequence_value
        end
        self.class.connection.shards_transaction([self.turntable_shard]) do
          if has_transactional_callbacks?
            add_to_transaction
          else
            sync_with_transaction_state if @transaction_state&.finalized?
            @transaction_state = self.turntable_shard.connection.transaction_state
          end
          remember_transaction_record_state

          begin
            status = yield
          rescue ActiveRecord::Rollback
            clear_transaction_record_state
            status = nil
          end

          raise ActiveRecord::Rollback unless status
        end
        status
      end

      def add_to_transaction
        return super unless self.class.turntable_enabled?

        self.turntable_shard.connection.add_transaction_record(self)
      end
    end
  end
end
