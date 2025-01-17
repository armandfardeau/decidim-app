# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = Rails.application.secrets.dig(:scaleway, :id).blank? ? :local : :scaleway

  # By default, files uploaded to Active Storage will be served from a private URL.
  # in production, you'll want to set this to :public so that files are served
  # unfortunately, this is not working with the current version of ActiveStorage
  # TODO: Update rails version and switch to public:true from active_storage
  config.active_storage.service_urls_expire_in = ENV.fetch("SERVICE_URLS_EXPIRE_IN") do
    if Rails.application.secrets.dig(:scaleway, :id).blank?
      "120000"
    else
      "1"
    end
  end.to_i.weeks

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV.fetch("FORCE_SSL", "1") == "1"

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different cache store in production.
  config.cache_store = if ENV["MEMCACHEDCLOUD_SERVERS"].present?
                         [:dalli_store, ENV["MEMCACHEDCLOUD_SERVERS"].split(","), {
                           username: ENV["MEMCACHEDCLOUD_USERNAME"], password: ENV["MEMCACHEDCLOUD_PASSWORD"]
                         }]
                       else
                         :mem_cache_store
                       end

  # Use a real queuing backend for Active Job (and separate queues per environment)
  config.active_job.queue_adapter = :sidekiq
  # see configuration for sidekiq in `config/sidekiq.yml`
  # config.active_job.queue_name_prefix = "development_app_#{Rails.env}"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # config.action_mailer.raise_delivery_errors = true
  # config.action_mailer.delivery_method = :letter_opener_web
  if ENV.fetch("ENABLE_LETTER_OPENER", "0") == "1"
    config.action_mailer.delivery_method = :letter_opener_web
    config.action_mailer.default_url_options = { port: 3000 }
  else
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: Rails.application.secrets.smtp_address,
      port: Rails.application.secrets.smtp_port,
      authentication: Rails.application.secrets.smtp_authentication,
      user_name: Rails.application.secrets.smtp_username,
      password: Rails.application.secrets.smtp_password,
      domain: Rails.application.secrets.smtp_domain,
      enable_starttls_auto: Rails.application.secrets.smtp_starttls_auto,
      openssl_verify_mode: "none"
    }

    if Rails.application.secrets.sendgrid
      config.action_mailer.default_options = {
        "X-SMTPAPI" => {
          filters: {
            clicktrack: { settings: { enable: 0 } },
            opentrack: { settings: { enable: 0 } }
          }
        }.to_json
      }
    end
  end

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.custom_options = lambda do |event|
    {
      remote_ip: event.payload[:remote_ip],
      params: event.payload[:params].except("controller", "action", "format", "utf8"),
      user_id: event.payload[:user_id],
      organization_id: event.payload[:organization_id],
      referer: event.payload[:referer]
    }
  end

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Global IDs are used to identify records and
  # are known to cause issue with moderation due to expiration
  # Setting this to 100 years should be enough
  config.global_id.expires_in = 100.years
end
