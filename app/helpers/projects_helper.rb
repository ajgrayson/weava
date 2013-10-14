module ProjectsHelper

    def share_project_path(project)
        '/projects/' + project.id.to_s + '/share'
    end

    def create_project_share_path(project)
        '/projects/' + project.id.to_s + '/create_share'
    end

    # def show_file_path(project, id)
    #     '/projects/' + project.id.to_s + '/showfile/' + id.to_s
    # end

    # def new_file_path(project)
    #     '/projects/' + project.id.to_s + '/newfile'
    # end 

end
