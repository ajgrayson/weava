require 'securerandom'

module ProjectManager

    def self.create_new_repo(project)
        # create upstream
        upstream = Rugged::Repository.init_at(project.upstream_path, :bare)

        # create user fork
        clone_repo(project.upstream_path, project.path)
    end

    def self.clone_repo(upstream_path, path)
        Rugged::Repository.clone_at(upstream_path, path, {:bare => true})
    end

    def self.get_repo(path)
        Rugged::Repository.new(path)
    end
    
    # def self.create_folder(repo, user, name) 
    #     foldername = name # sanitize_filename(name)

    #     if not repo.head_unborn?
    #         tree = repo.lookup(repo.head.target).tree
    #         folder = tree.get_entry(foldername)
    #     else
    #         folder = false
    #     end

    #     if folder
    #         return false
    #     else
    #         # write the content
    #         oid = repo.write(name + " Folder", :blob)

    #         index = repo.index
    #         index.add(:path => foldername, :oid => oid, :mode => 040000)
    #         index.write

    #         options = {}
    #         options[:tree] = index.write_tree(repo)
    #         options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
    #         options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
    #         options[:message] ||= "Added folder " + foldername
    #         options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
    #         options[:update_ref] = "HEAD"

    #         Rugged::Commit.create(repo, options)

    #         return true
    #     end

    # end

    # def self.get_folder(repo, folder_id)
    #     tree = repo.lookup(repo.head.target).tree
    #     file = tree.get_entry_by_oid(folder_id)

    #     return {
    #         :id => file[:oid],
    #         :name => file[:name],
    #         :items => []
    #     }
    # end

    def self.get_file(repo, file_id)
        tree = repo.lookup(repo.head.target).tree
        file = tree.get_entry_by_oid(id)
        blob = Rugged::Blob.lookup(repo, file[:oid])

        return { 
            :id => file[:oid],
            :name => file[:name],
            :content => blob.content
        }
    end

    def self.create_file(repo, user, name, content, folder_id = nil)
        filename = name #sanitize_filename(name)

        if not repo.head_unborn?
            tree = repo.lookup(repo.head.target).tree
            file = tree.get_entry(filename)
        else
            file = false
        end

        # if folder_id
        #     folder = tree.get_entry_by_oid(folder_id)
        #     path += folder[:name] + "/"
        # end

        if file
            return false
        else
            # write the content
            oid = repo.write(content, :blob)

            index = repo.index
            index.add(:path => filename, :oid => oid, :mode => 0100644)
            index.write
            
            options = {}
            options[:tree] = index.write_tree(repo)
            options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
            options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
            options[:message] ||= "Added item " + filename
            options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
            options[:update_ref] = "HEAD"

            Rugged::Commit.create(repo, options)

            return true
        end
    end

    def self.update_file(repo, user, oid, content, message)
        new_oid = repo.write(content, :blob)
        
        tree = repo.lookup(repo.head.target).tree
        file = tree.get_entry_by_oid(oid)
        index = repo.index

        index.add(:path => file[:name], :oid => new_oid, :mode => 0100644)
        index.write

        commit_message = message
        if commit_message == "" or commit_message == nil
            commit_message = "Updated " + file[:name]
        end

        options = {}
        options[:tree] = index.write_tree(repo)
        options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:message] ||= commit_message
        options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
        options[:update_ref] = "HEAD"

        Rugged::Commit.create(repo, options)

        new_oid
    end

    def self.delete_file(repo, user, oid, message)
        index = repo.index

        commit = repo.lookup(repo.head.target)
        tree = commit.tree

        file = tree.get_entry_by_oid(oid)

        index.remove(file[:name])

        index.write

        commit_message = message
        if commit_message == "" or commit_message == nil
            commit_message = "Deleted " + file[:name]
        end

        options = {}
        options[:tree] = index.write_tree(repo)
        options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:message] ||= commit_message
        options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
        options[:update_ref] = "HEAD"

        Rugged::Commit.create(repo, options)
    end

    # Get the tree of files for a repo
    def self.get_repo_tree(project_id, repo)
        if !repo.empty?
            commit = repo.lookup(repo.head.target)
            
            tree = []
            commit.tree.each do |item|
                tree.push({
                    :id => item[:oid],
                    :project_id => project_id,
                    :name => item[:name],
                    :type => item[:type]
                })
            end
            
            tree
        end
    end

    # Get a walker to list out the history
    # of commits in a repo
    def self.get_repo_commit_walker(repo)
        if !repo.empty?
            walker = Rugged::Walker.new(repo)
            walker.sorting(Rugged::SORT_TOPO)
            walker.push(repo.head.target)

            walker
        end
    end

    def self.get_file_history(repo, file) 
        walker = get_repo_commit_walker(repo)
        history = []
        uniquecommits = {}
        walker.each do |commit|
            tree = commit.tree
            tree.each do |leaf|
                if leaf[:name] == file[:name] and not uniquecommits[leaf[:oid]] #and file[:oid] != leaf[:oid]
                    cm = FileHistoryItem.new(
                        leaf[:name], 
                        leaf[:oid], 
                        commit.time, 
                        commit.message, 
                        commit.author[:name], 
                        commit.oid)

                    uniquecommits[leaf[:oid]] = true
                    history.push(cm)
                end
            end
        end
        history
    end

    def self.get_object(repo, oid) 
        Rugged::Object.lookup(repo, oid)
    end

    private
        def self.sanitize_filename(filename)
          # Split the name when finding a period which is preceded by some
          # character, and is followed by some character other than a period,
          # if there is no following period that is followed by something
          # other than a period (yeah, confusing, I know)
          fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

          # We now have one or two parts (depending on whether we could find
          # a suitable period). For each of these parts, replace any unwanted
          # sequence of characters with an underscore
          fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

          # Finally, join the parts with a period and return the result
          return fn.join '.'
        end

    class FileHistoryItem

        attr_accessor :name, :time, :oid, :message, :author, :commit_oid

        def initialize(name, oid, time, message, author, commit_oid)
            @name = name
            @oid = oid
            @time = time
            @message = message
            @author = author
            @commit_oid = commit_oid
        end
    end
end