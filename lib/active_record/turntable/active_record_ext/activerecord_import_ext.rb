module ActiveRecord::Turntable
  module ActiveRecordExt
    module ActiverecordImportExt
      # @note override for sequencer injection
      # @see https://github.com/zdennis/activerecord-import/blob/master/lib/activerecord-import/import.rb#L1002-L1037
      private def values_sql_for_columns_and_attributes(columns, array_of_attributes) # :nodoc:
        # connection gets called a *lot* in this high intensity loop.
        # Reuse the same one w/in the loop, otherwise it would keep being re-retreived (= lots of time for large imports)
        connection_memo = connection

        array_of_attributes.map do |arr|
          my_values = arr.each_with_index.map do |val, j|
            column = columns[j]

            # be sure to query sequence_name *last*, only if cheaper tests fail, because it's costly
            if val.nil? && Array(primary_key).first == column.name && !sequence_name.blank?
              if sequencer_enabled?
                self.next_sequence_value
              else
                connection_memo.next_value_for_sequence(sequence_name)
              end
            elsif val.respond_to?(:to_sql)
              "(#{val.to_sql})"
            elsif column
              if respond_to?(:type_caster)                                         # Rails 5.0 and higher
                type = type_for_attribute(column.name)
                val = !type.respond_to?(:subtype) && type.type == :boolean ? type.cast(val) : type.serialize(val)
                connection_memo.quote(val)
              elsif column.respond_to?(:type_cast_from_user)                       # Rails 4.2
                connection_memo.quote(column.type_cast_from_user(val), column)
              else                                                                 # Rails 3.2, 4.0 and 4.1
                if serialized_attributes.include?(column.name)
                  val = serialized_attributes[column.name].dump(val)
                end
                # Fixes #443 to support binary (i.e. bytea) columns on PG
                val = column.type_cast(val) unless column.type && column.type.to_sym == :binary
                connection_memo.quote(val, column)
              end
            else
              raise ArgumentError, "Number of values (#{arr.length}) exceeds number of columns (#{columns.length})"
            end
          end
          "(#{my_values.join(',')})"
        end
      end
    end

    begin
      require "activerecord-import"
      require "activerecord-import/base"
      r# equire "activerecord-import/active_record/adapters/mysql2_adapter"
      # ActiveRecord::Turntable::ConnectionProxy.include(ActiveRecord::Import::Mysql2Adapter)
      (class << ActiveRecord::Base; self; end).prepend(ActiverecordImportExt)
    rescue LoadError # rubocop:disable Lint/HandleExceptions
    end
  end
end
