#
# force TestFixtures to begin transaction with all shards.
#
require "active_record/fixtures"

module ActiveRecord
  module TestFixtures
    # rubocop:disable Style/ClassVars, Style/RedundantException
    def setup_fixtures(config = ActiveRecord::Base)
      if pre_loaded_fixtures && !use_transactional_fixtures
        raise RuntimeError, "pre_loaded_fixtures requires use_transactional_fixtures"
      end

      @fixture_cache = {}
      @fixture_connections = []
      @@already_loaded_fixtures ||= {}
      @connection_subscriber = nil

      # Load fixtures once and begin transaction.
      if run_in_transaction?
        if @@already_loaded_fixtures[self.class]
          @loaded_fixtures = @@already_loaded_fixtures[self.class]
        else
          @loaded_fixtures = load_fixtures(config)
          @@already_loaded_fixtures[self.class] = @loaded_fixtures
        end

        # Begin transactions for connections already established
        ActiveRecord::Base.force_connect_all_shards!
        @fixture_connections = enlist_fixture_connections
        @fixture_connections.each do |connection|
          connection.begin_transaction joinable: false
          connection.pool.lock_thread = true
        end

        # When connections are established in the future, begin a transaction too
        @connection_subscriber = ActiveSupport::Notifications.subscribe("!connection.active_record") do |_, _, _, _, payload|
          spec_name = payload[:spec_name] if payload.key?(:spec_name)

          if spec_name
            begin
              connection = ActiveRecord::Base.connection_handler.retrieve_connection(spec_name)
            rescue ConnectionNotEstablished
              connection = nil
            end

            if connection && !@fixture_connections.include?(connection)
              connection.begin_transaction joinable: false
              connection.pool.lock_thread = true
              @fixture_connections << connection
            end
          end
        end

      # Load fixtures for every test.
      else
        ActiveRecord::FixtureSet.reset_cache
        @@already_loaded_fixtures[self.class] = nil
        @loaded_fixtures = load_fixtures(config)
      end

      # Instantiate fixtures for every test if requested.
      instantiate_fixtures if use_instantiated_fixtures
    end
    # rubocop:enable Style/ClassVars, Style/RedundantException
  end
end
