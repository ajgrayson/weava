$ ->
    signinLink = $('#signin')
    signoutLink = $('#signout')

    if signinLink
        signinLink.click () -> 
            navigator.id.request()

    if signoutLink
        signoutLink.click () -> 
            navigator.id.logout()

    navigator.id.watch
        loggedInUser: currentUser,
        onlogin: (assertion) -> 
            as = assertion
            $.ajax
                type: 'POST'
                url: '/auth/authenticate'
                data:
                    assertion: assertion
                success: () ->
                    window.location = '/'
                error: (xhr, status, err) ->
                    navigator.id.logout()
                    console.log('Login failure: ', err)
            
            return null
        onlogout: () ->
            $.ajax
                type: 'POST'
                url: '/auth/logout'
                success: () -> 
                    window.location = '/'
                error: (xhr, status, err) ->
                    console.log('Logout failure: ', err)

            return null
    return this
