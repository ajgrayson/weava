crumb :root do
  link "Home", root_path
end

crumb :projects do
  link "Projects", projects_path
end

crumb :project do |project|
  link project.name, project_path(project)
  parent :projects
end

crumb :project_compare do |project|
  link "Compare", project_path(project)
  parent :project, project
end

crumb :project_conflicts do |project|
  link "Conflicts", conflicts_project_path(project)
  parent :project, project
end

crumb :item_conflict do |project, conflict|
    title = conflict[:ours][:path]
    path = item_conflict_path(project.id, conflict[:ours][:oid])

    link title, path
    parent :project_conflicts, project
end

# crumb :issue do |issue|
#   link issue.title, issue_path(issue)
#   parent :project_issues, issue.project
# end

# If you want to split your breadcrumbs configuration over multiple files, you
# can create a folder named `config/breadcrumbs` and put your configuration
# files there. All *.rb files (e.g. `frontend.rb` or `products.rb`) in that
# folder are loaded and reloaded automatically when you change them, just like
# this file (`config/breadcrumbs.rb`).