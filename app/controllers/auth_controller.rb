require "net/http"
require "uri"

class AuthController < ApplicationController

	def login
		# nothing to see here... carry on
	end
	
    def logout
        cookies.delete :user_id
        render text: 'ok'
    end

	def authenticate
        # The request has to have an assertion for us to verify
        if not params.has_key?(:assertion)
            render text: 'Forbidden', status: :forbidden
        else
            # Send the assertion to Mozilla's verifier service.
            assertion = params[:assertion]
            audience = Rails.application.config.persona_url

            http = Net::HTTP.new('verifier.login.persona.org', 443)
            http.use_ssl = true
            
            headers = {
                'Content-Type' => 'application/x-www-form-urlencoded',
            }
            data = "audience=#{audience}&assertion=#{assertion}"
            resp = http.post("/verify", data, headers)
            
            # debugger

            res = JSON.parse(resp.body())

            # Did the verifier respond?
            if res['status'] == 'okay'
                # cookies[:email] = res['email']

                users = User.where("email = ?", res['email'])
                
                if users.empty?
                    user = User.new(:email => res['email'])

                    if !user.save
                        # oh bother... not again
                    else
                        # send mail to let us know a new one signed up
                        LogMailer.newuser_email(user).deliver
                    end
                else
                    user = users[0]
                end

                cookies[:user_id] = user.id

                render text: 'ok'
            else
                # Oops, something failed. Abort.
                render text: 'Server Error', status: :internal_server_error
            end
        end
	end
end
