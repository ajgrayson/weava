require 'open-uri'
require 'net/http'

class ZendeskService
    def self.oauth_url(project_id)
        oauth_uri = URI::encode(
            Rails.application.config.zendesk_oauth_uri)
        response_type = 'code'
        redirect_uri = URI::encode(
            Rails.application.config.zendesk_redirect_uri)
        client_id = URI::encode(
            Rails.application.config.zendesk_client_id)
        scope = URI::encode('read write')
        state = URI::encode(project_id.to_s)

        return "#{oauth_uri}?response_type=#{response_type}" + 
                "&redirect_uri=#{redirect_uri}" +
                "&client_id=#{client_id}&scope=#{scope}" + 
                "&state=#{state}"
    end

    def self.get_oauth_access_token(code, error, error_description)
        grant_type = 'authorization_code'
        client_id = URI::encode(
            Rails.application.config.zendesk_client_id)
        client_secret = URI::encode(
            Rails.application.config.zendesk_app_id)
        redirect_uri = URI::encode(
            Rails.application.config.zendesk_redirect_uri)
        scope = URI::encode('read')

        uri = URI(Rails.application.config.zendesk_oauth_token_uri)

        access_token = nil
        Net::HTTP.start(
            uri.host, 
            uri.port, 
            :use_ssl => true) do |https|

            request = Net::HTTP::Post.new(uri.path)
            request.set_form_data(
                    "grant_type" => grant_type,
                    "client_id" => client_id,
                    "client_secret" => client_secret,
                    "redirect_uri" => redirect_uri,
                    "scope" => "read",
                    "code" => code
                )

            response = https.request(request)
            res = JSON.parse(response.body)
            access_token = res['access_token']
        end

        return access_token
    end

    

    def get_categories(project_id)
        zd_project = ZendeskProject.where("project_id = ?", 
            project_id).first

        uri = URI(
            Rails.application.config.zendesk_api_base_uri + 
            '/forums.json')

        res = nil
        Net::HTTP.start(
            uri.host, 
            uri.port, 
            :use_ssl => true) do |https|

            request = Net::HTTP::Get.new(uri.path)
            request['Authorization'] = 'Bearer ' + zd_project.token
            response = https.request(request)
            res = JSON.parse(response.body)
        end
        return res
    end

end
