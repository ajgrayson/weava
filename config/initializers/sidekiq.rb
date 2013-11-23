require 'sidekiq'
require 'sidekiq-status'

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
  end
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end

module NewRelic
  class SidekiqException
    def call(worker, msg, queue)
      begin
        yield
      rescue => exception
        NewRelic::Agent.notice_error(exception, :custom_params => msg)
        raise exception
      end
    end
  end
end
 
::Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add ::NewRelic::SidekiqException
  end
end