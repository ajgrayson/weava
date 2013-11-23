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
        
        nav.each do |item|
            path = item["path"]
            id = item["id"]
            text = item["text"]
            icon = item["icon"]
            match = item["match"]
            match_exact = item["match_exact"]

            id_attribute = id ? "id=\"#{id}\"" : ""
            icon_html = icon ? "<i class=\"#{icon}\"></i> " : ""
            active = ""

            if current_user and current_user.name
                text = text.sub '{username}', current_user.name
            end

            if match
                if match.kind_of?(Array)
                    match.each do |mtc|
                        if request.path.starts_with?(mtc)
                            active = "class=\"active\""
                            break
                        end
                    end
                else
                    active = request.path.starts_with?(match) ? "class=\"active\"" : ""
                end
            else # match_exact is default
                active = request.path == path ? "class=\"active\"" : ""
            end

            if (item["anonymous_only"] and not current_user) or (current_user and not item["anonymous_only"]) or (item["anonymous"])
                html += "<li #{active}>"
                html += "<a #{id_attribute} href=\"#{path}\">#{icon_html}#{text}</a>"
                html += "</li>"
            end
        end

        return html.html_safe
    end

end
