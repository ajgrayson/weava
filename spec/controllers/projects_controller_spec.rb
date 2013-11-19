require "spec_helper"

describe ProjectsController do

    before(:each) do
        session_id = 'abc123'

        @user = User.create!(name: "User Test",
            email: "user@test.com", session_id: session_id)

        @service = ProjectService.new
        @service.create_project(@user, "Test Project")
        @project = Project.where("name = ? and user_id = ?", 
            "Test Project", @user.id).first

        request.cookies[:sessid] = session_id
        request.cookies[:beta] = true
    end

    after(:each) do
        service = ProjectService.new
        service.delete_project(@project, @user)
    end

    describe "GET #index" do
        it "responds successfully with an HTTP 200 status code" do
            get :index
            expect(response).to be_success
            expect(response.status).to eq(200)
        end
    end

    describe "GET #show" do
        it "responds successfully with an HTTP 200 status code" do
            get :show, :id => @project.id
            expect(response).to be_success
            expect(response.status).to eq(200)
        end
    end

    describe "GET #edit" do
        it "responds successfully with an HTTP 200 status code" do
            get :edit, :id => @project.id
            expect(response).to be_success
            expect(response.status).to eq(200)
        end
    end

    describe "GET #share" do
        it "responds successfully with an HTTP 200 status code" do
            get :share, :id => @project.id
            expect(response).to be_success
            expect(response.status).to eq(200)
        end
    end

    describe "POST #create_share" do
        it "redirects successfully successfully" do
            user2 = User.create!(name: "User 2", email: "user2@email.com")

            post :create_share, :id => @project.id, :email => user2.email

            expect(response).to redirect_to(:controller => "projects", 
                :action => "show")
        end
    end

    describe "POST #accept_share" do
        it "redirects successfully" do
            user2 = User.create!(name: "User 2", email: "user23@email.com", 
                session_id: 'abc456')

            share = @service.share_project(@project, user2.email)

            request.cookies[:sessid] = 'abc456'
            post :accept_share, :code => share.code

            expect(flash[:notice]).to eq("New Project Added")
        end
    end

    describe "POST #create" do
        it "redirects successfully" do
            post :create, :project => { :name => "Test Project 2" }

            expect(response).to redirect_to(:controller => 'projects',
                :action => 'index')
        end
    end

    describe "POST #update" do
        it "redirects successfully" do
            post :update, :id => @project.id, :project => { :name => "Test Project 2" }

            expect(response).to redirect_to(:controller => 'projects',
                :action => 'index')
        end
    end

    describe "GET #new" do
        it "responds successfully with an HTTP 200 status code" do
            get :compare, :id => @project.id
            expect(response).to be_success
            expect(response.status).to eq(200)
        end
    end

    describe "POST #push" do
        it "redirects successfully" do
            post :push, :id => @project.id
            expect(response).to redirect_to(:controller => "projects",
                :action => "show")
        end
    end

    describe "POST #merge" do
        it "redirects successfully" do
            post :merge, :id => @project.id
            expect(response).to redirect_to(:controller => "projects",
                :action => "show")
        end
    end

    describe "GET #conflicts" do
        it "responds successfully with an HTTP 200 status code" do
            get :conflicts, :id => @project.id
            expect(response).to be_success
            expect(response.status).to eq(200)
        end
    end

    describe "GET #undo_merge" do
        it "redirects successfully" do
            get :undo_merge, :id => @project.id
            expect(response).to redirect_to(:controller => "projects",
                :action => "show")
        end
    end

    describe "GET #save_merge" do
        it "redirects successfully" do
            get :save_merge, :id => @project.id
            expect(response).to redirect_to(:controller => "projects",
                :action => "show")
        end
    end

end