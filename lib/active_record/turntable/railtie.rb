module ActiveRecord::Turntable
  class Railtie < Rails::Railtie
    # rake_tasks do
    #   require "active_record/turntable/active_record_ext/database_tasks"
    #   load "active_record/turntable/railties/databases.rake"
    # end

    # rails loading hook
    ActiveSupport.on_load(:before_initialize) do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.include(ActiveRecord::Turntable)
      end
    end

    # initialize
    initializer "turntable.initialize_clusters" do |app|
      app.paths.add "config/turntable", with: "config/turntable.rb"
      app.paths.add "config/turntable", with: "config/turntable.yml"

      ActiveSupport.on_load(:active_record) do
        path = app.paths["config/turntable"].existent.first
        self.turntable_configuration_file = path

        if path
          reset_turntable_configuration(Configuration.load(turntable_configuration_file, Rails.env))
        else
          # FIXME: suppress this warning during rails g turntable:install
          warn("[activerecord-turntable] config/turntable.{rb,yml} is not found. skipped initliazing cluster.")
        end
      end
    end
  end
end
