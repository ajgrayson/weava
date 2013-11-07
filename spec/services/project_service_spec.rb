require "spec_helper"

describe ProjectService do
  it "gets projects for user" do
    project1 = Project.create(name: "Project 1", user_id: 1, owner: true)
    user1 = User.create(name: "User 1")

    allow(Project).to receive(:where) { [project1] }

    allow(User).to receive(:find_by_id) { user1 }

    service = ProjectService.new

    projects = service.get_projects_for_user(1)

    expect(projects.length).to eq(1)
    expect(projects.first[:name]).to eq(project1.name)
  end
end