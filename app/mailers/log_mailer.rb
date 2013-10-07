class LogMailer < ActionMailer::Base
  default from: "Weava Log <log@weava.io>"

  def newuser_email(user) 
    @user = user
    @env = Rails.env.production? ? "PROD" : "DEV"
    mail(to: "ajgrayson+weavalogs@gmail.com", subject: "[Weava " + @env + "] New User Signed In")
  end

  def share_project_email(project, sharing_user, receiving_user, share)
    @project = project
    @sharing_user = sharing_user
    @receiving_user = receiving_user

    base_url = Rails.application.config.base_url
    @share_url = base_url + '/projects/accept/' + share.code 

    subject = sharing_user.name + ' wants to share a Weava project with you'

    mail(to: receiving_user.email, subject: subject)
  end
end
