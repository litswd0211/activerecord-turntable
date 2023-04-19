module ActiveRecord::Turntable
  module ActiveRecordExt
    module AbstractAdapter
      extend Compatibility

      def self.prepended(klass)
        klass.prepend(self.compatible_module)
        klass.class_eval { protected :log }
      end

      def translate_exception_class(e, sql, binds)
        begin
          message = "#{e.class.name}: #{e.message}: #{sql} : #{turntable_shard_name}"
        rescue Encoding::CompatibilityError
          message = "#{e.class.name}: #{e.message.force_encoding sql.encoding}: #{sql} : #{turntable_shard_name}"
        end

        exception = translate_exception(e, message: message, sql: sql, binds: binds)
        exception.set_backtrace e.backtrace
        exception
      end
      protected :translate_exception_class

      # @note override for append current shard name
      # rubocop:disable Style/HashSyntax, Style/MultilineMethodCallBraceLayout
      module V6_0
        def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil)
          @instrumenter.instrument(
            "sql.active_record",
            sql:                  sql,
            name:                 name,
            binds:                binds,
            type_casted_binds:    type_casted_binds,
            statement_name:       statement_name,
            connection:           self,
            turntable_shard_name: turntable_shard_name) do
            begin
              @lock.synchronize do
                yield
              end
            rescue => e
              raise translate_exception_class(e, sql, binds)
            end
          end
        end
      end
      # rubocop:enable Style/HashSyntax, Style/MultilineMethodCallBraceLayout


      def turntable_shard_name=(name)
        @turntable_shard_name = name.to_s
      end

      def turntable_shard_name
        instance_variable_defined?(:@turntable_shard_name) ? @turntable_shard_name : nil
      end
    end
  end
end
