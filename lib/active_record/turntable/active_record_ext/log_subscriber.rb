require "active_record/log_subscriber"

module ActiveRecord::Turntable
  module ActiveRecordExt
    module LogSubscriber
      # @note prepend to add shard name logging
      def sql(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        payload = event.payload

        return if ActiveRecord::LogSubscriber::IGNORE_PAYLOAD_NAMES.include?(payload[:name])

        name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
        name  = "#{name} [Shard: #{payload[:turntable_shard_name]}]" if payload[:turntable_shard_name]
        name  = "CACHE #{name}" if payload[:cached]
        sql   = payload[:sql]
        binds = nil

        unless (payload[:binds] || []).empty?
          casted_params = type_casted_binds(payload[:type_casted_binds])
          binds = "  " + payload[:binds].zip(casted_params).map { |attr, value|
            render_bind(attr, value)
          }.inspect
        end

        name = colorize_payload_name(name, payload[:name])
        sql  = color(sql, sql_color(sql), true) if colorize_logging

        debug "  #{name}  #{sql}#{binds}"
      end
    end
  end
end
