Weava::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  #config.app_uid = 'johnathangrayson'
  #config.app_gid = 'johnathangrayson'

  # Persona
  config.persona_url = 'http://localhost:3000'
  config.base_url = 'http://localhost:3000'

  # git
  config.git_root_path = '/Users/johnathangrayson/Development/weava-git-repos/'
  config.git_user_path = '/Users/johnathangrayson/Development/weava-git-user-repos/'

  # action mailer
  config.action_mailer.smtp_settings = {
    :address => 'smtp.mailgun.org',
    :user_name => 'postmaster@weava.mailgun.org',
    :password => '05eazmku-k42',
    :domain => 'weava.mailgun.org',
    :authentication => :plain
  }

  config.cache_store = :redis_store, 'redis://localhost:6379/0/cache', { 
      expires_in: 90.minutes }

  # Zendesk
  config.zendesk_app_id = 'c1d5a4f317ae34f006b826a0ed14fcbed3524e9dfce0e0600104e5aacccea538'
  config.zendesk_oauth_uri = 'https://weava.zendesk.com/oauth/authorizations/new'
  config.zendesk_redirect_uri = 'http://localhost:3000/zendesk_auth'
  config.zendesk_redirect_token_uri = 'http://localhost:3000/zendesk_token'
  config.zendesk_client_id = 'weava'
  config.zendesk_oauth_token_uri = 'https://weava.zendesk.com/oauth/tokens'
  config.zendesk_api_base_uri = 'https://weava.zendesk.com/api/v2'

  # Desk
  config.desk_api_consumer_key = 'MLPPya4pNgv2sONjsedo'
  config.desk_api_consumer_secret = 'BrKfEtHInv7Os0m0g9DCksWCGCn1cQ4J4Gf4NLhU'
  config.desk_callback_uri = 'http://localhost:3000/desk/auth_redirect'
  config.desk_api_uri = 'https://weava.desk.com'
  config.desk_subdomain = 'weava'
  config.desk_support_email = 'support@weava.io'

end
