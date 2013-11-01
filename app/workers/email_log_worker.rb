class EmailLogWorker

    include Sidekiq::Worker

    def perform(email)
        LogMailer.log_email("User with email " + email + " just logged in").deliver
    end

end