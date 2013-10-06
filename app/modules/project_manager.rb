require 'securerandom'

module ProjectManager

    def self.create_new_repo(path)
        Rugged::Repository.init_at(path, :bare)
    end

    def self.get_repo(path)
        Rugged::Repository.new(path)
    end

    def self.create_file(repo, user, name, content)
        filename = sanitize_filename(name)

        # write the content
        oid = repo.write(content, :blob)

        index = repo.index
        index.add(:path => filename, :oid => oid, :mode => 0100644)
        index.write

        options = {}
        options[:tree] = index.write_tree(repo)
        options[:author] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:committer] = { :email => user.email, :name => user.name, :time => Time.now }
        options[:message] ||= "Creating new file"
        options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
        options[:update_ref] = 'HEAD'

        Rugged::Commit.create(repo, options)
    end

    def self.update_file(repo, user, oid, content)
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
    end

    def self.delete_file(repo, user, oid)
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

    # Get the tree of files for a repo
    def self.get_repo_tree(path)
        repo = Rugged::Repository.new(path)
        if !repo.empty?
            commit = repo.lookup(repo.head.target)
            
            commit.tree
        end
    end

    # Get a walker to list out the history
    # of commits in a repo
    def self.get_repo_commit_walker(path)
        repo = Rugged::Repository.new(path)
        if !repo.empty?
            walker = Rugged::Walker.new(repo)
            walker.sorting(Rugged::SORT_TOPO)
            walker.push(repo.head.target)

            walker
        end
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
end