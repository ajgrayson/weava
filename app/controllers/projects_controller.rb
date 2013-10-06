class ProjectsController < ApplicationController

    def index

        user_id = cookies[:user_id]
        @projects = Project.where("user_id = ?", user_id)

    end

    def show
        @project = Project.find_by_id(params[:id])

        path = @project.path

        repo = Rugged::Repository.new(path)

        if !repo.empty?
            commit = repo.lookup(repo.head.target)
            @tree = commit.tree

            @walker = Rugged::Walker.new(repo)
            @walker.sorting(Rugged::SORT_TOPO)
            @walker.push(repo.head.target)

        end

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

        # get the repo
        repo = Rugged::Repository.new(path)

        # write the content
        oid = repo.write(content, :blob)

        index = repo.index

        index.add(:path => filename + ".txt", :oid => oid, :mode => 0100644)

        index.write

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

    def editfile

        id = params[:id]
        oid = params[:oid]

        @project = Project.find_by_id(params[:id])

        path = @project.path

        repo = Rugged::Repository.new(path)

        commit = repo.lookup(repo.head.target)
        tree = commit.tree

        @file = tree.get_entry_by_oid(oid)
        @blob = Rugged::Blob.lookup(repo, @file[:oid])

    end

    def updatefile

        commit = params[:commit]
        id = params[:id]
        oid = params[:oid]

        project = Project.find_by_id(id)

        path = project.path

        # get the repo
        repo = Rugged::Repository.new(path)

        user = User.find_by_id(project.user_id)

        if commit == 'Save'
            
            content = params[:content]

            # write the content
            new_oid = repo.write(content, :blob)


            commit = repo.lookup(repo.head.target)
            tree = commit.tree

            file = tree.get_entry_by_oid(oid)


            index = repo.index

            index.add(:path => file[:name], :oid => new_oid, :mode => 0100644)

            index.write

            options = {}
            options[:tree] = index.write_tree(repo)
            options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
            options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
            options[:message] ||= "Updating " + file[:name]
            options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
            options[:update_ref] = 'HEAD'

            Rugged::Commit.create(repo, options)

        else

            if commit == 'Delete'

                index = repo.index

                commit = repo.lookup(repo.head.target)
                tree = commit.tree

                file = tree.get_entry_by_oid(oid)

                index.remove(file[:name])

                index.write

                options = {}
                options[:tree] = index.write_tree(repo)
                options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
                options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
                options[:message] ||= "Deleting " + file[:name]
                options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
                options[:update_ref] = 'HEAD'

                Rugged::Commit.create(repo, options)
            end

        end
        redirect_to :project

    end

end
