# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

//= require codemirror
//= require codemirror/mode/markdown/markdown
//= require marked/lib/marked

$ ->
    content = document.getElementById('content')
    contentView = document.getElementById('content_view')

    if content
        codeMirror = CodeMirror.fromTextArea(content, {
            mode: 'markdown',
            theme: 'prose-bright'
        })

    if contentView
        contentSource = $('#content_source')
        html = $(contentSource).val()
        $(contentView).html(marked(html))

    actionPull = $('[data-action=pull]')
    actionPush = $('[data-action=push]')

    doPushAction = -> 
        
    doPullAction = (e) -> 
        projectId = e.currentTarget.getAttribute('data-id')
        
        $.ajax(
            url: '/projects/' + projectId + '/pull'
        ).done( -> 
            alert 'done'
        ) 

    actionPull.click(doPullAction)
    actionPush.click(doPushAction)

    this