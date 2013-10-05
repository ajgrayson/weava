module ApplicationHelper

    # Generates the navigation for the specified menu
    # The menus are defined in the config/navigation.json
    # 
    # ACCESS RESTRICTIONS
    # - anonymous_only => shown if user is not logged in but not if they beta_access_required
    # - anonymous => shown regardless of whether the user is logged in or not
    # - none => shown only if the user is logged in
    def generate_navigation(name)

        # TODO: cache the navigation!!!
        file = File.read("config/navigation.json")
        json = JSON.parse(file)
        nav = json[name]
        html = ""
        user = @current_user

        nav.each do |item|
            path = item["path"]
            id = item["id"]
            text = item["text"]
            icon = item["icon"]
            id_attribute = id ? "id=\"#{id}\"" : ""
            icon_html = icon ? "<i class=\"icon-#{icon}\"></i> " : ""
            active = request.path == path ? "class=\"active\"" : ""

            if (item["anonymous_only"] and not user) or (user and not item["anonymous_only"]) or (item["anonymous"])
                html += "<li #{active}>"
                html += "<a #{id_attribute} href=\"#{path}\">#{icon_html}#{text}</a>"
                html += "</li>"
            end
        end

        return html.html_safe
    end

end
