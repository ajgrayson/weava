require 'securerandom'

class GitRepo

    attr_accessor :repo, :path

    def initialize(path = nil)
        @path = path
        if path
            @repo = Rugged::Repository.new(path)
        end
    end

    def self.init_at(upstream_path, path, user)
        # create upstream
        Rugged::Repository.init_at(upstream_path, :bare)

        us_repo = GitRepo.new(upstream_path)
        us_repo.create_file(user, "README.md", "")

        # create user fork
        Rugged::Repository.clone_at(upstream_path, path, {:bare => true})

        return self.new(path)
    end

    def clone_to(path)
        Rugged::Repository.clone_at(@path, path, {:bare => true})
    end

    def get_commit_walker()
        if !@repo.empty?
            walker = Rugged::Walker.new(@repo)
            walker.sorting(Rugged::SORT_TOPO)
            walker.push(@repo.head.target)
            return walker
        end
    end

    def get_current_tree(project_id)
        if !@repo.empty?
            commit = @repo.lookup(@repo.head.target)
            
            tree = []
            commit.tree.each do |item|
                tree.push({
                    :id => item[:oid],
                    :project_id => project_id,
                    :name => item[:name],
                    :type => item[:type]
                })
            end
            
            return tree
        end
    end

    def get_file(file_id)
        tree = @repo.lookup(@repo.head.target).tree
        file = tree.get_entry_by_oid(file_id)
        blob = Rugged::Blob.lookup(@repo, file[:oid])

        return { 
            :id => file[:oid],
            :name => file[:name],
            :content => blob.content
        }
    end

    def create_file(user, name, content)
        filename = name #sanitize_filename(name)

        if not @repo.head_unborn?
            tree = @repo.lookup(@repo.head.target).tree
            file = tree.get_entry(filename)
        else
            file = false
        end

        if file
            return false
        else
            # write the content
            oid = @repo.write(content, :blob)

            index = @repo.index
            index.add(:path => filename, :oid => oid, :mode => 0100644)
            index.write
            
            options = {}
            options[:tree] = index.write_tree(@repo)
            options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
            options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
            options[:message] ||= "Added item " + filename
            options[:parents] = repo.empty? ? [] : [ @repo.head.target ].compact
            options[:update_ref] = "HEAD"

            Rugged::Commit.create(@repo, options)

            return true
        end
    end

    def update_file(user, oid, content, message)
        new_oid = @repo.write(content, :blob)
        
        tree = @repo.lookup(@repo.head.target).tree
        file = tree.get_entry_by_oid(oid)
        index = @repo.index

        index.add(:path => file[:name], :oid => new_oid, :mode => 0100644)
        index.write

        commit_message = message
        if commit_message == "" or commit_message == nil
            commit_message = "Updated " + file[:name]
        end

        options = {}
        options[:tree] = index.write_tree(@repo)
        options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:message] ||= commit_message
        options[:parents] = repo.empty? ? [] : [ @repo.head.target ].compact
        options[:update_ref] = "HEAD"

        Rugged::Commit.create(@repo, options)

        new_oid
    end

    def delete_file(user, oid, message)
        index = @repo.index

        commit = @repo.lookup(@repo.head.target)
        tree = commit.tree

        file = tree.get_entry_by_oid(oid)

        index.remove(file[:name])

        index.write

        commit_message = message
        if commit_message == "" or commit_message == nil
            commit_message = "Deleted " + file[:name]
        end

        options = {}
        options[:tree] = index.write_tree(@repo)
        options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:message] ||= commit_message
        options[:parents] = repo.empty? ? [] : [ @repo.head.target ].compact
        options[:update_ref] = "HEAD"

        Rugged::Commit.create(@repo, options)
    end

    def get_file_version(commit_id, version_id)
        tree = @repo.lookup(commit_id).tree
        file = tree.get_entry_by_oid(version_id)
        
        blob = Rugged::Blob.lookup(@repo, version_id)

        item = {
            :id => version_id,
            :name => file[:name],
            :content => blob.content
        }
    end

    # Get a walker to list out the history
    # of commits in a repo
    def get_repo_commit_walker()
        if !@repo.empty?
            walker = Rugged::Walker.new(repo)
            walker.sorting(Rugged::SORT_TOPO)
            walker.push(@repo.head.target)

            walker
        end
    end

    def get_file_history(oid) 
        file = get_file(oid)
        walker = get_repo_commit_walker()

        history = []
        uniquecommits = {}
        
        walker.each do |commit|
            tree = commit.tree
            tree.each do |leaf|
                if leaf[:name] == file[:name] and not uniquecommits[leaf[:oid]]
                    
                    uniquecommits[leaf[:oid]] = true
                    history.push({
                        :oid => leaf[:oid],
                        :name => leaf[:name],
                        :time => commit.time,
                        :message => commit.message,
                        :author => commit.author[:name],
                        :commit_oid => commit.oid
                    })
                end
            end
        end
        history
    end

    def get_blob(oid)
        Rugged::Blob.lookup(@repo, oid)
    end

    def get_object(oid) 
        Rugged::Object.lookup(@repo, oid)
    end

    def diff(downstream_path)
        src_repo = Rugged::Repository.new(downstream_path)
        src_tree = src_repo.lookup(src_repo.head.target).tree

        des_tree = @repo.lookup(@repo.head.target).tree
        
        diff = src_tree.diff(des_tree)
        diff_list = []
        diff.each_delta do |diff|
            diff_list.push({
                old_path: diff.old_file[:path],
                new_path: diff.new_file[:path],
                status: diff.status,
                similarity: diff.similarity
            })
        end
        return diff_list
    end

end

