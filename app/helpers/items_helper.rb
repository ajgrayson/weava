module ItemsHelper

    def project_item_version_path(project_id, item_id, version_id, commit_id)
        version_project_item_path(@item[:project_id], @item[:id]) + '?vid=' + version_id + '&cid=' + commit_id

        # '/projects/' + project_id.to_s + '/version/' + version_id.to_s + '?cid=' + commit_id.to_s + '&ooid=' + item_id.to_s
    end

end
