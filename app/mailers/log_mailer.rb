class LogMailer < ActionMailer::Base
  default from: "Weava Log <log@weava.io>"

  def newuser_email(user) 
    @user = user
    @env = Rails.env.production? ? "PROD" : "DEV"
    mail(to: "ajgrayson+weavalogs@gmail.com", subject: "[Weava " + @env + "] New User Signed In")
  end
end
