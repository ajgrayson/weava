module ProjectsHelper

    def share_project_path(project)
        '/projects/' + project.id.to_s + '/share'
    end

    # def show_file_path(project, id)
    #     '/projects/' + project.id.to_s + '/showfile/' + id.to_s
    # end

    # def new_file_path(project)
    #     '/projects/' + project.id.to_s + '/newfile'
    # end 

end
