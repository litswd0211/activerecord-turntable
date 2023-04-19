module ActiveRecord::Turntable
  module ActiveRecordExt
    module Persistence
      extend ActiveSupport::Concern
      extend Compatibility

      ::ActiveRecord::Persistence.class_eval do
        # @note Override to add sharding scope on reloading
        def reload(options = nil)
          self.class.connection.clear_query_cache

          finder_scope = if turntable_enabled? && self.class.primary_key != self.class.turntable_shard_key.to_s
                           self.class.unscoped.where(self.class.turntable_shard_key => self.send(turntable_shard_key))
                         else
                           self.class.unscoped
                         end

          fresh_object =
            if options && options[:lock]
              finder_scope.lock(options[:lock]).find(id)
            else
              finder_scope.find(id)
            end

          @attributes = fresh_object.instance_variable_get("@attributes")
          @new_record = false
          self
        end

        # @note Override to add sharding scope on `update_columns`
        def update_columns(attributes)
          raise ActiveRecord::ActiveRecordError, "cannot update a new record" if new_record?
          raise ActiveRecord::ActiveRecordError, "cannot update a destroyed record" if destroyed?

          attributes = attributes.transform_keys do |key|
            name = key.to_s
            self.class.attribute_aliases[name] || name
          end

          attributes.each_key do |key|
            verify_readonly_attribute(key)
          end

          constraints = { self.class.primary_key => id_in_database }
          if self.class.sharding_condition_needed?
            constraints[self.class.turntable_shard_key] = self[self.class.turntable_shard_key]
          end

          affected_rows = self.class._update_record(
            attributes,
            constraints,
          )

          attributes.each do |k, v|
            write_attribute_without_type_cast(k, v)
          end

          affected_rows == 1
        end

        private

          def _update_row(attribute_names, attempted_action = "update")
            constraints = { self.class.primary_key => id_in_database }
            if self.class.sharding_condition_needed?
              constraints[self.class.turntable_shard_key] = self[self.class.turntable_shard_key]
            end

            attributes = attributes_with_values(attribute_names)

            self.class.unscoped._update_record(
              attributes,
              constraints,
            )
          end

          def _delete_row
            constraints = { self.class.primary_key => id_in_database }
            if self.class.sharding_condition_needed?
              constraints[self.class.turntable_shard_key] = self[self.class.turntable_shard_key]
            end

            self.class._delete_record(constraints)
          end
      end
    end
  end
end
