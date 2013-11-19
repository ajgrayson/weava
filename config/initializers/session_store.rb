# Be sure to restart your server when you modify this file.

# Weava::Application.config.session_store :cookie_store, key: '_weava_session'
Weava::Application.config.session_store :redis_store, key: '_weava_session'