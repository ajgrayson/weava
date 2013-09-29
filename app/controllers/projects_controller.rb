# require 'rugged'

class ProjectsController < ApplicationController

    def index

        user_id = cookies[:user_id]
        @projects = Project.where("user_id = ?", user_id)

    end

    def show
        @project = Project.find_by_id(params[:id])

        path = @project.path

        repo = Rugged::Repository.new(path)
        
        commit = repo.lookup(repo.head.target)

        @tree = commit.tree

    end

    def new
        
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

    def create
        base_path = Rails.application.config.git_root_path
        
        user_id = cookies[:user_id]
        name = params[:project][:name]
        path = File.join(base_path, 'user_' + user_id, name);
        
        project = Project.new(:name => name, :path => path, :user_id => user_id)

        if project.save()

            Rugged::Repository.init_at(path, :bare)

            redirect_to :projects
        else
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
        project = Project.find_by_id(params[:id])

        path = project.path
        filename = params[:name]
        content = params[:content]

        user = User.find_by_id(project.user_id)

        repo = Rugged::Repository.new(path)

        oid = repo.write(content, :blob)
        index = Rugged::Index.new
        index.add(:path => filename + ".txt", :oid => oid, :mode => 0100644)

        options = {}
        options[:tree] = index.write_tree(repo)

        options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:message] ||= "Creating new file"
        options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
        options[:update_ref] = 'HEAD'

        Rugged::Commit.create(repo, options)

        redirect_to :project
    end

end
