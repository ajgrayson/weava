class UsersController < ApplicationController

	# def new
	# 	@user = User.new
	# end

	# def create
	# 	@user = User.new(params[:user].permit(:email, :password))
	# 	if @user.save 
	# 		redirect_to @user
	# 	else 
	# 		render 'new'
	# 	end
	# end

	def show
		user_id = params[:id]
		if not user_id
			user_id = cookies[:user_id]
		end

		if user_id
			@user = User.find_by_id(user_id)
			if not @user
				redirect_to '/auth/login'
			end
		else
			redirect_to '/auth/login'
		end
	end

	def edit
		@user = User.find_by_id(params[:id])
		if not @user
			redirect_to :back
		end
	end

	def update
		@user = User.find(params[:id])

		if @user.update(params[:user].permit(:name))
			redirect_to @user
		else
			render 'edit'
		end
	end

end
