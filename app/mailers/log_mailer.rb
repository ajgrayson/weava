class LogMailer < ActionMailer::Base
  default from: "Weava Log <log@weava.io>"

  def newuser_email(user) 
    @user = user
    mail(to: 'ajgrayson+weavalogs@gmail.com', subject: '[Weava] New User Signed In')
  end
end
