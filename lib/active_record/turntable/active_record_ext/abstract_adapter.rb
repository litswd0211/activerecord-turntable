module ActiveRecord::Turntable
  module ActiveRecordExt
    module ConnectionAdapters
      module AbstractAdapter
        # TODO: to private method
        def translate_exception_class(e, sql, binds)
          begin
            message = "#{e.class.name}: #{e.message}: #{sql} : #{turntable_shard_name}"
          rescue Encoding::CompatibilityError
            message = "#{e.class.name}: #{e.message.force_encoding sql.encoding}: #{sql} : #{turntable_shard_name}"
          end

          exception = translate_exception(
            e, message: message, sql: sql, binds: binds
          )
          exception.set_backtrace e.backtrace
          exception
        end
        private :translate_exception_class

        def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil, async: false, &block) # :doc:
          @instrumenter.instrument(
            "sql.active_record",
            sql:               sql,
            name:              name,
            binds:             binds,
            type_casted_binds: type_casted_binds,
            statement_name:    statement_name,
            async:             async,
            connection:        self,
            turntable_shard_name: turntable_shard_name,
            &block
          )
        rescue ActiveRecord::StatementInvalid => ex
          raise ex.set_query(sql, binds)
        end
        private :log

        def turntable_shard_name=(name)
          @turntable_shard_name = name.to_s
        end

        def turntable_shard_name
          instance_variable_defined?(:@turntable_shard_name) ? @turntable_shard_name : nil
        end
      end
    end
  end
end
