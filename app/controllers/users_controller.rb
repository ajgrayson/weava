class UsersController < ApplicationController

	def show
		
	end

	def edit
		if not @user
			redirect_to :back
		end
	end

	def update
		if @user.update(params[:user].permit(:name))
			redirect_to @user
		else
			render 'edit'
		end
	end

	def setup
		
	end

	def save_setup
		if @user.update(params[:user].permit(:name))
			redirect_to '/'
		else
			redirect_to 'setup'
		end
	end

end
