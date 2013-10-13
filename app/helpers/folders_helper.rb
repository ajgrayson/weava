module FoldersHelper

    def new_folder_item_path(project_id, folder_id)
        '/projects/' + project_id.to_s + '/items/new?folder_id='+folder_id
    end

end
