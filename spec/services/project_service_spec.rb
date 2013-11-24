require "spec_helper"

describe ProjectService do
    before(:each) do
        @service = ProjectService.new
    end

    describe "authorize_project" do
        it "returns a project if the user is authorized to view it" do
            project = Project.new(name: "Project 1", user_id: 1)
            user = Project.new(name: "User 1", id: 1)

            join = double("join")
            allow(join).to receive(:find_by) { project }
            allow(Project).to receive(:joins) { join }
            allow(Project).to receive(:find_by_id) { project }

            auth_project = @service.authorize_project(project.id, 
                user.id)

            expect(auth_project).to eq(project)
        end

        it "returns nil if the user is not authorized to view it" do
            project = Project.new(name: "Project 1", user_id: 2)
            user = Project.new(name: "User 1", id: 1)

            allow(Project).to receive(:find_by_id) { project }

            auth_project = @service.authorize_project(project.id, 
                user.id)

            expect(auth_project).to eq(nil)
        end
    end

    describe "is_configured" do
        it "returns an error if the project is not correctly configured" do
            project_name = "Test Project"
            user_id = 1
            project_code = 'testcode'

            user = User.new(
                    :name => 'Test User',
                    :id => user_id,
                    :email => 'test@user.com'
                )

            project = Project.new(
                    :name => project_name,
                    :user_id => user.id,
                    :code => project_code
                )

            res = @service.is_configured(project, user)

            expect(res[:error]).to eq('Storage not configured')
        end
    end

    describe "get_projects_for_user" do
        it "gets projects for user" do
            project1 = Project.new(name: "Project 1", user_id: 1, 
                owner: true)
            user1 = User.new(name: "User 1")

            join = double("join")
            allow(join).to receive(:where) { [project1] }
            allow(Project).to receive(:joins) { join }

            allow(User).to receive(:find_by_id) { user1 }

            projects = @service.get_projects_for_user(1)

            expect(projects.length).to eq(1)
            expect(projects.first[:name]).to eq(project1.name)
        end
    end

    describe "share_project" do

        it "returns valid share if project is shared" do
            project = Project.new(name: "Project 1", id: 1, 
                user_id: 1)
            user = User.new(name: "User 1", id: 2)

            allow(User).to receive(:find_by) { user }
            allow(ProjectShare).to receive(:create) { true }
            allow(EmailShareWorker).to receive(:perform_async) { 
                true }

            share = @service.share_project(project, 'test@test.com')

            expect(share.project_id).to eq(1)
            expect(share.owner_id).to eq(1)
            expect(share.user_id).to eq(2)
        end

        it "returns nil if the user is not registered" do
            project = Project.new(name: "Project 1", id: 1, 
                user_id: 1)
            user = User.new(name: "User 1", id: 2)

            allow(User).to receive(:where) { [] }
            allow(ProjectShare).to receive(:save) { true }
            allow(EmailShareWorker).to receive(:perform_async) { 
                true }

            share = @service.share_project(project, 'test@test.com')

            expect(share).to eq(nil)
        end
    end

    describe "accept_share" do

        it "returns nil if the share is valid and converted into a project" do
            user1_id = 1
            user2_id = 2
            project_id = 1
            share_code = 'abc'

            project1 = Project.new(name: "Project 1", id: 
                project_id, user_id: user1_id)

            user2 = User.new(name: "User 2", id: user2_id)

            share = ProjectShare.new(project_id: project_id, 
                owner_id: user1_id, 
                user_id: user2_id, code: share_code)

            allow(ProjectShare).to receive(:where) { [share] }
            allow(ProjectShare).to receive(:update) { true }

            allow(Project).to receive(:save) { true }
            allow(Project).to receive(:find_by_id) { project1 }

            repo = double("repo")
            allow(GitRepo).to receive(:new) { repo }
            allow(repo).to receive(:fork_to) { true }

            error = @service.accept_share(user2, share_code)

            expect(error).to eq(nil)
        end

        it "returns an error message if the share doesn't exist" do
            project1 = Project.new(name: "Project 1", id: 1, 
                user_id: 1)

            user2 = User.new(name: "User 2", id: 2)

            allow(ProjectShare).to receive(:where) { [] }

            error = @service.accept_share(user2, 'abc')

            expect(error).to eq('Share not found')
        end

        it "returns an error message if the share is for a different user" do
            user1_id = 1
            user2_id = 2
            user3_id = 3
            project_id = 1
            share_code = 'abc'

            project1 = Project.new(name: "Project 1", 
                id: project_id, user_id: user1_id)

            user2 = User.new(name: "User 2", id: user2_id)

            share = ProjectShare.new(project_id: project_id, 
                owner_id: user1_id, 
                user_id: user3_id, code: share_code)

            allow(ProjectShare).to receive(:where) { [share] }
            
            error = @service.accept_share(user2, share_code)

            expect(error).to eq('Share not found')
        end

        it "returns an error message if the share project is deleted" do
            user1_id = 1
            user2_id = 2
            project_id = 1
            share_code = 'abc'

            user2 = User.new(name: "User 2", id: user2_id)

            share = ProjectShare.new(project_id: project_id, 
                owner_id: user1_id, user_id: user2_id, 
                code: share_code)

            allow(ProjectShare).to receive(:where) { [share] }
            allow(ProjectShare).to receive(:update) { true }

            allow(Project).to receive(:find_by_id) { nil }

            error = @service.accept_share(user2, share_code)

            expect(error).to eq('Project not found')
        end

    end

    describe "create_project" do

        it "returns nil if the project is successfully created" do
            user_id = 1
            project_name = "Test Project"
            project_id = 2

            user = User.new(name: "User 1", id: user_id)
            project = Project.new(name: project_name, id: project_id)

            allow(Project).to receive(:where) { [] }
            allow(Project).to receive(:create) { project }
            allow(ProjectRole).to receive(:create) { nil }
            allow(GitRepo).to receive(:init_at) { true }

            res = @service.create_project(user, project_name)

            expect(res[:error]).to eq(nil)
        end

        it "returns an error if a project with that name already exists" do
            user_id = 1
            project_id = 1
            project_name = "Test Project"

            user = User.new(name: "User 1", id: user_id)
            project = Project.new(name: project_name, 
                id: project_id)

            allow(Project).to receive(:where) { [project] }

            res = @service.create_project(user, project_name)

            expect(res[:error]).to eq('A project already exists ' + 'with that name')
        end

    end

    describe "delete_project" do
        it "removes the project from the database" do
            user = User.create!(name: "User1", 
                email: "user@email.com")

            res = @service.create_project(user, "Test Project")

            project = Project.find_by_id(res[:id])
            project_id = project.id

            project2 = Project.find_by_id(project_id)
            expect(project2).not_to eq(nil)

            @service.delete_project(project2, user)

            project3 = Project.find_by_id(project_id)
            expect(project3).to eq(nil)
        end
    end
end
