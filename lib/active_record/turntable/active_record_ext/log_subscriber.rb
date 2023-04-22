require "active_record/log_subscriber"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module LogSubscriber
      def sql(event)
        payload = event.payload

        return if ActiveRecord::LogSubscriber::IGNORE_PAYLOAD_NAMES.include?(payload[:name])

        name = if payload[:async]
          "ASYNC #{payload[:name]} (#{payload[:lock_wait].round(1)}ms) (db time #{event.duration.round(1)}ms)"
        else
          "#{payload[:name]} (#{event.duration.round(1)}ms)"
        end
        name  = "#{name} [Shard: #{payload[:shard]}]" if payload[:shard] != :default
        name  = "CACHE #{name}" if payload[:cached]
        sql   = payload[:sql]
        binds = nil

        if payload[:binds]&.any?
          casted_params = type_casted_binds(payload[:type_casted_binds])

          binds = []
          payload[:binds].each_with_index do |attr, i|
            attribute_name = if attr.respond_to?(:name)
              attr.name
            elsif attr.respond_to?(:[]) && attr[i].respond_to?(:name)
              attr[i].name
            else
              nil
            end

            filtered_params = filter(attribute_name, casted_params[i])

            binds << render_bind(attr, filtered_params)
          end
          binds = binds.inspect
          binds.prepend("  ")
        end

        name = colorize_payload_name(name, payload[:name])
        sql  = color(sql, sql_color(sql), bold: true) if colorize_logging

        debug "  #{name}  #{sql}#{binds}"
      end
    end
  end
end
