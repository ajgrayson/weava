require "oauth/consumer"

class DeskApiClient

    def initialize(access_token = nil, access_token_secret = nil)
        @access_token = access_token
        @access_token_secret = access_token_secret
    end

    def get_request_token
        return oauth_consumer.get_request_token(
            :oauth_callback => Rails.application.config.desk_callback_uri)
    end

    def get_access_token(oauth_verifier, request_token, request_token_secret)
        request_token = OAuth::RequestToken.new(
            oauth_consumer,
            request_token,
            request_token_secret
        )

        token = request_token.get_access_token(
            :oauth_verifier => oauth_verifier
        )

        return token
    end

    def get_site_name
        resp = oauth_consumer.request(
            :get,
            '/api/v2/site_settings',
            oauth_access_token,
            { :scheme => :query_string }
        )

        if resp.code == "200"
            data = JSON.parse(resp.body)

            settings = data['_embedded']['entries']
            name = settings.select{|hash| hash['name'] == 'company_name'}[0]['value']

            return {
                value: name
            }
        else
            return {
                error: "Authentication Failed"
            }
        end
    end

    def desk
        if not @configured_desk
            Desk.configure do |config|
                config.support_email = Rails.application.config.desk_support_email
                config.subdomain = Rails.application.config.desk_subdomain
                config.consumer_key = Rails.application.config.desk_api_consumer_key
                config.consumer_secret = Rails.application.config.desk_api_consumer_secret
                config.oauth_token = @access_token
                config.oauth_token_secret = @access_token_secret
                config.version = 'v2'
            end
            @configured_desk = true
        end
        return Desk
    end

    def get_topics
        topics = []
        desk.topics[:_embedded][:entries].each do |topic|
            id = topic[:_links][:self][:href].split('/').last
            topics.push({
                :id => id,
                :name => topic[:name],
                :description => topic[:description]
            })
        end
        return topics
    end

    def get_articles(topic_id)
        articles = []
        desk.articles(topic_id)[:_embedded][:entries].each do |article|
            id = article[:_links][:self][:href].split('/').last
            articles.push({
                :id => id,
                :subject => article[:subject],
                :body => article[:body]
            })
        end
        return articles
    end

    private
        def oauth_access_token
            if @access_token and @access_token_secret
                return OAuth::AccessToken.new(
                    oauth_consumer,
                    @access_token,
                    @access_token_secret
                )
            else
                return nil
            end
        end

        def oauth_consumer
            return OAuth::Consumer.new(
                Rails.application.config.desk_api_consumer_key,
                Rails.application.config.desk_api_consumer_secret,
                :site => Rails.application.config.desk_api_uri,
                :scheme => :header
            )
        end

end