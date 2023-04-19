module ActiveRecord::Turntable
  module ActiveRecordExt
    module LockingOptimistic
      ::ActiveRecord::Locking::Optimistic.class_eval <<-EOD
        private

        def _update_row(attribute_names, attempted_action = "update")
          return super unless locking_enabled?

          begin
            locking_column = self.class.locking_column
            previous_lock_value = read_attribute_before_type_cast(locking_column)
            attribute_names << locking_column

            self[locking_column] += 1

            constraints = {
              self.class.primary_key => id_in_database,
              locking_column => previous_lock_value
            }
            if self.class.sharding_condition_needed?
              constraints[self.class.turntable_shard_key] = self[self.class.turntable_shard_key]
            end

            affected_rows = self.class._update_record(
              attributes_with_values(attribute_names),
              constraints,
            )

            if affected_rows != 1
              raise ActiveRecord::StaleObjectError.new(self, attempted_action)
            end

            affected_rows

          # If something went wrong, revert the locking_column value.
          rescue Exception
            self[locking_column] = previous_lock_value.to_i
            raise
          end
        end
      EOD
    end
  end
end
