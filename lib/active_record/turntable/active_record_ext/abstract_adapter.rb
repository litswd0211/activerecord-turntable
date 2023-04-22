module ActiveRecord::Turntable
  module ActiveRecordExt
    module AbstractAdapter
      private
        def translate_exception_class(e, sql, binds)
          message = "#{e.class.name}: #{e.message}: #{sql} : #{shard}"

          exception = translate_exception(
            e, message: message, sql: sql, binds: binds
          )
          exception.set_backtrace e.backtrace
          exception
        end

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
            shard:             shard,
            &block
          )
        rescue ActiveRecord::StatementInvalid => ex
          raise ex.set_query(sql, binds)
        end

        def shard
          @pool.shard if @pool.respond_to?(:shard)
        end
    end
  end
end
