require 'securerandom'

class ProjectsController < ApplicationController
    before_action :authorize_project

    # Ensure the user should be able to access this project
    def authorize_project
        id = params[:id]

        # Only apply this on actions where
        # we're accessing a project directly via
        # the id param
        if id
            @project = Project.find_by_id(id)
            if not @project or @project.user_id != @user.id
                redirect_to '/404.html'
            end
        end
    end

    def index
        @projects = Project.where("user_id = ?", @user.id)
    end

    def show
        repo = ProjectManager.get_repo(@project.path)
        @walker = ProjectManager.get_repo_commit_walker(repo)
        @tree = ProjectManager.get_repo_tree(repo)
    end

    def new
        # nothing here... carry on
    end

    def edit
        @project = Project.find(params[:id])
    end

    def delete 
        # project = Project.find_by_id(params[:id])

        # debugger

        # project.remove()

        # redirect_to :projects
    end

    def share

    end

    def create_share
        email = params[:email]

        users = User.where("email = ?", email)
        if not users.empty? 
            user = users[0]

            share = ProjectShare.new(
                :project_id => @project.id, 
                :owner_id => @user.id, 
                :user_id => user.id, 
                :code => SecureRandom.uuid)

            share.save

            LogMailer.share_project_email(@project, @user, user, share).deliver
            
            redirect_to project_path(@project), notice: 'Project shared with ' + email
        else
            @error = 'There are no users with email ' + email
            render 'share'
        end
    end

    def accept_share
        share_code = params[:code]

        if share_code
            shares = ProjectShare.where("code = ?", share_code)
            if not shares.empty?
                share = shares[0]
                if share.user_id == @user.id
                    # we got a live one bob... what do we do?

                    project = Project.find_by_id(share.project_id)

                    if project
                        new_project = Project.new(:name => project.name, :user_id => @user.id, :owner => false, :code => project.code)                        
                        new_project.save

                        ProjectManager.clone_repo(project.upstream_path, new_project.path)                        
                    end

                    redirect_to projects_path, notice: 'New Project Added'
                else
                    redirect_to projects_path, notice: 'Invalid share'
                end
            else
                redirect_to projects_path, notice: 'Invalid share'
            end
        else
            redirect_to projects_path, notice: 'Invalid share'
        end
    end

    # Creates a new project and sets up a git repo
    # TODO: make this async...
    def create
        name = params[:project][:name]
        
        existingProjects = Project.where('name = ?', name)
        if existingProjects.empty?
            project = Project.new(:name => name, :user_id => @user.id, :owner => true)

            # Since its a new project so we need to tell it to init
            # and generate the code and path fields
            project.init()

            if project.save()
                ProjectManager.create_new_repo(project)

                redirect_to :projects
            else
                render 'new'
            end
        else
            # TODO: better feedback why this failed... async lookup??
            render 'new'
        end
    end

    def update
        project = Project.find_by_id(params[:id])

        if(project.update(params[:project].permit(:name))) 
            redirect_to :projects
        else
            render 'edit'
        end
    end

    def newfile
        @project = Project.find_by_id(params[:id])
    end

    def createfile
        name = params[:name]
        content = params[:content]
        
        # get the repo
        repo = ProjectManager.get_repo(@project.path)
        ProjectManager.create_file(repo, @user, name, content)
        
        redirect_to :project
    end

    def editfile
        oid = params[:oid]
        repo = ProjectManager.get_repo(@project.path)
        tree = repo.lookup(repo.head.target).tree

        @file = tree.get_entry_by_oid(oid)
        @blob = Rugged::Blob.lookup(repo, @file[:oid])
    end

    def updatefile
        commit = params[:commit]
        message = params[:message]
        content = params[:content]
        oid = params[:oid]
        
        # get the repo
        repo = ProjectManager.get_repo(@project.path)
        
        if commit == 'Save'            
            nid = ProjectManager.update_file(repo, @user, oid, content, message)

            redirect_to show_file_path(@project, nid)
        elsif commit == 'Delete'
            ProjectManager.delete_file(repo, @user, oid, message)

            redirect_to project_path(@project)
        end
    end

    def showfile 
        oid = params[:oid]
        repo = ProjectManager.get_repo(@project.path)
        tree = repo.lookup(repo.head.target).tree

        @file = tree.get_entry_by_oid(oid)
        @walker = ProjectManager.get_file_history(repo, @file)
        @blob = Rugged::Blob.lookup(repo, @file[:oid])
    end

    def showfileversion
        oid = params[:oid]
        cid = params[:cid]
        repo = ProjectManager.get_repo(@project.path)
        tree = repo.lookup(cid).tree

        @file = tree.get_entry_by_oid(oid)
        @blob = Rugged::Blob.lookup(repo, oid)

        @ooid = params[:ooid]
    end

end
