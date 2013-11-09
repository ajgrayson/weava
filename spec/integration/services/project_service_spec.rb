require "spec_helper"

describe ProjectService do
    before(:each) do
        @service = ProjectService.new
    end

    describe "get_projects_for_user" do
        it "gets projects for user including pending shares" do
            user = User.create!(name: "User 1", email: 'test@user.com')
            user2 = User.create!(name: "User 2", email: 'test2@user.com')

            owned_project = Project.create!(name: "Project 1", 
                user_id: user.id, owner: true)

            not_owned_project = Project.create!(name: "Project 2", 
                user_id: user2.id, owner: true)

            share = ProjectShare.create!(project_id: not_owned_project.id,
                owner_id: user2.id, user_id: user.id, code: 'test')

            projects = @service.get_projects_for_user(user.id)

            expect(projects.length).to eq(2)
            expect(projects.first[:name]).to eq(owned_project.name)
            expect(projects.last[:name]).to eq(not_owned_project.name)
        end
    end

    describe "authorize_project" do
        it "returns a project if the user is authorized to view it" do
            project_name = "Project 1"
            user_id = 1

            project = Project.create!(name: project_name, user_id: user_id)

            auth_project = @service.authorize_project(project.id, user_id)

            expect(auth_project.name).to eq(project_name)
            expect(auth_project.user_id).to eq(user_id)
        end
    end

    describe "share_project" do
        it "shares a project with another user" do
            user_email = 'user1@email.com'

            user1 = User.create!(name: 'User 1', email: user_email)
            user2 = User.create!(name: 'User 2', email: 'user2@email.com')
            project = Project.create!(name: 'Test Project', user_id: user2.id)

            allow(EmailShareWorker).to receive(:perform_async) { nil }

            share = @service.share_project(project, user_email)

            expect(share).not_to eq(nil)
            expect(share.user_id).to eq(user1.id)
        end

        it "returns nil if the user doesn't exist" do
            user_email = 'user1@email.com'

            user2 = User.create!(name: 'User 2', email: 'user2@email.com')
            project = Project.create!(name: 'Test Project', user_id: user2.id)

            share = @service.share_project(project, user_email)

            expect(share).to eq(nil)
        end
    end

    describe "accept_share" do
        it "creates a project for a user if the share is valid" do
            share_code = 'abc123'
            user = User.create!(name: "User 1", email: "user1@email.com")
            user2 = User.create!(name: "User 2", email: "user2@email.com")

            project = Project.create(name: "Project Test", user_id: user.id)

            share = ProjectShare.create!(project_id: project.id, owner_id: user.id,
                user_id: user2.id, code: share_code)

            repo = double("repo")
            allow(GitRepo).to receive(:new) { repo }
            allow(repo).to receive(:fork_to) { nil }

            error = @service.accept_share(user2, share_code)

            expect(error).to eq(nil)

            share2 = ProjectShare.find_by_id(share.id)
            expect(share2.accepted).to eq(true)
        end
    end

    describe "create_project" do
        it "creates a new project" do
            user = User.create!(name: 'User 1', email: 'test@user.com')
            project_name = 'Test Project'

            allow(GitRepo).to receive(:init_at) { nil }

            error = @service.create_project(user, project_name)

            expect(error).to eq(nil)
        end

        it "fails to create a new project if the name isn't unique" do
            project_name = 'Test Project'
            user = User.create!(name: 'User 1', email: 'test@user.com')
            project = Project.create!(name: project_name, user_id: user.id)

            error = @service.create_project(user, project_name)

            expect(error).to eq('A project already exists with that name')
        end
    end

end
