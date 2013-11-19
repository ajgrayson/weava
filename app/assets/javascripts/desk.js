// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

function check_progress() {
    var stage = $('[data-stage]').attr('data-stage');
    $.ajax({
        url: '/desk/check_sync_progress?stage=' + stage
    }).done(function(res) {
        if (res.status === 'Done') {
            window.location = res.redirect_url;
        } else {
            $('.status-message').html(res.status);
            $('.progress-bar').css('width', res.value + '%');
        }
    });
}

$(function () {

    var page = $('[data-page]').attr('data-page');
    if(page === 'desk_sync_progress') {
        setInterval(check_progress, 1000);
    }

});