require "spec_helper"

describe DeskService do
    before(:each) do
        @service = DeskService.new
    end

    describe "create_project" do
        it "successfully creates a desk project" do
            project_id = 1
            desk_project_id = 2
            user_id = 3
            token = 'token'
            secret = 'secret'
            user_name = 'test user'
            project_name = 'test desk project'

            user = User.create(:name => user_name,
                :email => 'test@user.com',
                :id => user_id)

            res = {
                :error => nil,
                :id => project_id
            }

            allow(ProjectService).to receive(:create_project) { 
                res }

            desk_project = DeskProject.new(
                :id => desk_project_id,
                :project_id => project_id)

            allow(DeskProject).to receive(:create!) { desk_project }

            new_project = @service.create_project(
                user, project_name, token, secret)
            debugger
            expect(new_project[:id]).to eq(desk_project_id)

        end

    end

end
