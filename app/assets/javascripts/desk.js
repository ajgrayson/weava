// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

function check_progress() {
    var job_id = $('[data-job-id]').attr('data-job-id');
    $.ajax({
        url: '/desk/check_sync_progress?job_id=' + job_id
    }).done(function(res) {
        if (res.redirect_url) {
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