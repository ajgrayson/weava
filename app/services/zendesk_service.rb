class ZendeskService

    def initialize(access_token)
        @access_token = access_token
    end

    def get_project_name()
        uri = URI(Rails.application.config.zendesk_api_base_uri + '/categories.json')
        res = nil
        Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |https|
            request = Net::HTTP::Get.new(uri.path)
            request['Authorization'] = 'Bearer ' + @access_token
            response = https.request(request)
            res = JSON.parse(response.body)
        end
        return res
    end

end
