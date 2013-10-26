module ItemsHelper

    def project_item_version_path(project_id, item_id, version_id, commit_id)
        version_project_item_path(@item[:project_id], @item[:id]) + '?vid=' +
            version_id + '&cid=' + commit_id
    end

    def project_conflicts_path(project_id) 
        '/projects/' + project_id.to_s + '/conflicts'
    end

    def item_conflict_path(project_id, item_id)
        '/projects/' + project_id.to_s + '/items/' + item_id.to_s + '/conflict'
    end

end
