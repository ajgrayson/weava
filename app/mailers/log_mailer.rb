class LogMailer < ActionMailer::Base
  default from: "Weava <no-reply@weava.io>"

  def newuser_email(user) 
    @user = user
    @env = Rails.env.production? ? "PROD" : "DEV"
    to = "ajgrayson+weavalogsnu@gmail.com"
    subject = "A new user signed into Weava (#{@env})"

    mail(to: to, subject: subject)
  end

  def log_email(message) 
    @message = message
    @env = Rails.env.production? ? "PROD" : "DEV"

    mail(to: "ajgrayson+weavalogs@gmail.com", subject: "Weava log (#{@env})")
  end

  def share_project_email(project, sharing_user, receiving_user, share)
    @project = project
    @sharing_user = sharing_user
    @receiving_user = receiving_user
    @base_url = Rails.application.config.base_url
    @share_url = "#{base_url}/projects/accept/#{share.code}"
    subject = "Weava project share from #{sharing_user.name}"

    mail(to: receiving_user.email, subject: subject)
  end
end
