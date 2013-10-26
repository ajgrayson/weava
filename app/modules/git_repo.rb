require 'securerandom'

class GitRepo

    attr_accessor :repo, :path

    def initialize(path = nil)
        @path = path
        if path
            @repo = Rugged::Repository.new(path)
        end
    end

    # create a new central repo, clone it to the user and 
    # prep it for action
    def self.init_at(origin_path, path, user)
        # create origin
        Rugged::Repository.init_at(origin_path, :bare)

        us_repo = GitRepo.new(origin_path)
        us_repo.create_file(user, "README.md", "")

        ds_repo = us_repo.fork_to(path)

        return ds_repo
    end

    def fork_to(path)
        Rugged::Repository.clone_at(@path, path, { :bare => true })

        repo = GitRepo.new(path)

        # after a clone it seems that we need to init the 
        # initial index ourselves. not sure why but this 
        # seems to work. otherwise any files already in the 
        # repo get blown away if we add another file...
        repo.update_index

        repo
    end

    # sets the repo index to the state of the current tree
    def update_index
        tree = @repo.lookup(@repo.head.target).tree
        @repo.index.read_tree(tree)
        @repo.index.write
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
            index.add(
                :path => filename, 
                :oid => oid, 
                :mode => 0100644)
            index.write
            
            options = {}
            options[:tree] = index.write_tree(@repo)
            options[:author] = { 
                :email => user.email, 
                :name => user.name, 
                :time => Time.now }
            options[:committer] = { 
                :email => user.email, 
                :name => user.name, 
                :time => Time.now }
            options[:message] ||= "Added item " + filename
            options[:parents] = repo.empty? ? [] : [ 
                @repo.head.target ].compact
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

        index.add(
            :path => file[:name], 
            :oid => new_oid, 
            :mode => 0100644)
        index.write

        commit_message = message
        if commit_message == "" or commit_message == nil
            commit_message = "Updated " + file[:name]
        end

        options = {}
        options[:tree] = index.write_tree(@repo)
        options[:author] = { 
            :email => user.email, 
            :name => user.name, 
            :time => Time.now }
        options[:committer] = { 
            :email => user.email, 
            :name => user.name, 
            :time => Time.now }
        options[:message] ||= commit_message
        options[:parents] = repo.empty? ? [] : [ 
            @repo.head.target ].compact
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
        options[:author] = { 
            :email => user.email, 
            :name => user.name, 
            :time => Time.now }
        options[:committer] = { 
            :email => user.email, 
            :name => user.name, 
            :time => Time.now }
        options[:message] ||= commit_message
        options[:parents] = repo.empty? ? [] : [ 
            @repo.head.target ].compact
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
    def get_commit_walker()
        history = []
        if !@repo.empty?
            walker = Rugged::Walker.new(repo)
            walker.sorting(Rugged::SORT_TOPO)
            walker.push(@repo.head.target)

            history = walker.take(5).to_a
        end
        history
    end

    def get_file_history(oid) 
        file = get_file(oid)
        walker = get_commit_walker()

        history = []
        uniquecommits = {}
        
        walker.each do |commit|
            tree = commit.tree
            tree.each do |leaf|
                if leaf[:name] == file[:name] and not 
                    uniquecommits[leaf[:oid]]
                    
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
        history.take(5)
    end

    def get_blob(oid)
        Rugged::Blob.lookup(@repo, oid)
    end

    def get_object(oid) 
        Rugged::Object.lookup(@repo, oid)
    end

    # pull down changes from origin
    def fetch_origin()
        remote = Rugged::Remote.lookup(@repo, 'origin')
        remote.connect(:fetch) do |r|
            r.download
            r.update_tips!
        end
    end

    # push the current master to the remote
    def push_to_origin(user)
        diff = origin_to_local_diff

        if diff[:diff].length > 0
            @repo.push('origin', ["+refs/heads/master"])
        end

        fetch_origin()
    end

    def is_fast_forward_to_origin()

        # a fast forward is when there are no
        # deltas between the local and the origin
        # but there are deltas between the origin
        # and the base

        origin_ref = Rugged::Reference.lookup(@repo, 
            'refs/remotes/origin/master')

        local = @repo.lookup(@repo.head.target)
        origin = @repo.lookup(origin_ref.target)

        merge_base = @repo.merge_base(@repo.head.target, 
            origin_ref.target)
        
        base = @repo.lookup(merge_base)

        diff_local = base.tree.diff(local.tree)

        diff_origin = base.tree.diff(origin.tree)
        
        return (diff_local.size == 0 and diff_origin.size > 0)
    end

    def in_sync()
        origin_ref = Rugged::Reference.lookup(@repo, 
            'refs/remotes/origin/master')

        merge_base_oid = @repo.merge_base(@repo.head.target, 
            origin_ref.target)

        merge_base_oid == origin_ref.target
    end

    def merge_from_origin(user)
        origin_ref = Rugged::Reference.lookup(@repo, 
            'refs/remotes/origin/master')

        local = @repo.lookup(@repo.head.target)
        origin = @repo.lookup(origin_ref.target)

        merge_base = @repo.merge_base(@repo.head.target, 
            origin_ref.target)

        base = @repo.lookup(merge_base)

        if is_fast_forward_to_origin()

            # do a fast-forward
            @repo.head.set_target(origin_ref.target)

            update_index()

            return true
        else

            index = local.tree.merge(origin.tree, base.tree)

            if index.conflicts?
                index.conflicts.each do |cf|
                    @repo.index.remove(cf[:ours][:path], 0)
                    @repo.index.conflict_add(cf)
                end

                @repo.index.write

                return false
            else
                # this should only be requied if there were merges
                # e.g. if a remote file was added then why are we 
                # making a commit rather than a fast forward???

                options = {}
                options[:tree] = index.write_tree(@repo)
                options[:author] = { 
                    :email => user.email, 
                    :name => user.name, 
                    :time => Time.now 
                }
                options[:committer] = { 
                    :email => user.email, 
                    :name => user.name, 
                    :time => Time.now 
                }
                options[:message] ||= "Merged in origin changes"
                options[:parents] = repo.empty? ? [] : [ 
                    @repo.head.target, origin_ref.target
                ].compact
                options[:update_ref] = "HEAD"

                Rugged::Commit.create(@repo, options)

                update_index()

                return true 
            end
        end
    end

    def undo_merge
        @repo.index.conflict_cleanup
        update_index
    end

    # use before merging in from origin
    # origin is new
    # local is old
    def origin_to_local_diff()
        origin_ref = Rugged::Reference.lookup(@repo, 
            'refs/remotes/origin/master')

        # new tree
        ot_tree = @repo.lookup(origin_ref.target).tree

        # old tree
        dst_tree = @repo.lookup(@repo.head.target).tree
        
        diff = ot_tree.diff(dst_tree)
        #diff = @repo.index.diff(ot_tree)
        diff_list = []
        diff.each_delta do |diff|
            diff_list.push({
                old_path: diff.old_file[:path],
                new_path: diff.new_file[:path],
                status: diff.status,
                similarity: diff.similarity
            })
        end

        return {
            :diff => diff_list,
            :patch => diff.patch
        }
    end

    def has_conflicts
        return @repo.index.conflicts?
    end

    def get_conflicts

        conflicts = []

        if @repo.index.conflicts?

            @repo.index.conflicts.each do |conf|
                ours = conf[:ours]
                theirs = conf[:theirs]

                if ours
                    blob = Rugged::Object.lookup(@repo, conf[:ours][:oid])
                    ours[:content] = blob.content 
                end

                if theirs
                    blob = Rugged::Object.lookup(@repo, conf[:theirs][:oid])
                    theirs[:content] = blob.content 
                end

                conflicts.push({
                    :ours => ours,
                    :theirs => theirs
                })

            end

        end

        conflicts
    end

    # TODO: fix this hack
    def get_conflict(id)

        conflict = {}

        if @repo.index.conflicts?

            conflicts = @repo.index.conflicts.select { |c|
                c[:ours][:oid] == id
            }

            conflict = conflicts[0]

            blob_ours = Rugged::Object.lookup(@repo, conflict[:ours][:oid])
            conflict[:ours][:content] = blob_ours.content

            blob_theirs = Rugged::Object.lookup(@repo, conflict[:theirs][:oid])
            conflict[:theirs][:content] = blob_theirs.content

            patch = blob_ours.diff(blob_theirs)
            conflict[:patch] = patch
            conflict[:patch_content] = flatten_patch(blob_ours.content, patch)

        end

        conflict

    end

    def flatten_patch(original, patch)
        original_lines = original.lines.map(&:chomp)
        
        patch.each_hunk do |hunk|
            hunk.each_line do |line|
                if line.line_origin == :addition
                    original_lines[line.new_lineno-1] = line.content
                end

                if line.line_origin == :deletion
                    #original_lines[line.old_lineno-1] = ""
                end
            end
        end
        content = original_lines.join("\n")
    end

    def resolve_conflict(id, content)

        path = get_conflict(id)[:ours][:path]
        oid = @repo.write(content, :blob)

        @repo.index.add(
            :path => path, 
            :oid => oid, 
            :mode => 0100644)

        @repo.index.conflict_remove(path)

        @repo.index.write

    end

    def commit_merge(user)
        origin_ref = Rugged::Reference.lookup(@repo, 
            'refs/remotes/origin/master')

        commit_to_head(@repo, @repo.index, user, "Merged with origin", [ 
                    @repo.head.target, origin_ref.target
                ].compact)
    end

    private

        def commit_to_head(repo, index, user, message, parents)
            options = {
                :tree => index.write_tree(@repo),
                :author => { 
                    :email => user.email, 
                    :name => user.name, 
                    :time => Time.now 
                },
                :committer => {
                    :email => user.email, 
                    :name => user.name, 
                    :time => Time.now 
                    },
                :message => message,
                :parents => parents,
                :update_ref => "HEAD"
            }

            Rugged::Commit.create(@repo, options)
        end

        def merge_local_to_origin(user)
            origin_ref = Rugged::Reference.lookup(@repo, 
                'refs/remotes/origin/master')

            des_tree = @repo.lookup(origin_ref.target).tree
            src_tree = @repo.lookup(@repo.head.target).tree
            
            index = src_tree.merge(des_tree)

            options = {}
            options[:tree] = index.write_tree(@repo)
            options[:author] = { 
                :email => user.email, 
                :name => user.name, 
                :time => Time.now }
            options[:committer] = { 
                :email => user.email, 
                :name => user.name, 
                :time => Time.now }
            options[:message] ||= "Merged in origin changes"
            options[:parents] = repo.empty? ? [] : [ 
                origin_ref.target ].compact
            options[:update_ref] = "refs/remotes/origin/master"

            Rugged::Commit.create(@repo, options)
        end

end

