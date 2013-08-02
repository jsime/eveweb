function ew_countdown (id) {
    el = $('#'+id);

    var duration = moment.duration(moment(el.attr('data')) - moment());
    var countdown = '';

    if (el.hasClass('short')) {
        if (duration.years() > 0) {
            countdown += ' ' + duration.years() + 'y'
        }

        if (duration.months() > 0) {
            countdown += ' ' + duration.months() + 'mo'
        }

        if (duration.days() > 0) {
            countdown += ' ' + duration.days() + 'd'
        }

        if (duration.hours() > 0) {
            countdown += ' ' + duration.hours() + 'h'
        }

        if (duration.minutes() > 0) {
            countdown += ' ' + duration.minutes() + 'm'
        }

        countdown += ' ' + duration.seconds() + 's'
    } else {
        if (duration.years() > 1) {
            countdown += ' ' + duration.years() + ' Years'
        } else if (duration.years() > 0) {
            countdown += ' 1 Year'
        }

        if (duration.months() > 1) {
            countdown += ' ' + duration.months() + ' Months'
        } else if (duration.months() > 0) {
            countdown += ' 1 Month'
        }

        if (duration.days() > 1) {
            countdown += ' ' + duration.days() + ' Days'
        } else if (duration.days() > 0) {
            countdown += ' 1 Day'
        }

        if (duration.hours() > 1) {
            countdown += ' ' + duration.hours() + ' Hours'
        } else if (duration.hours() > 0) {
            countdown += ' 1 Hour'
        }

        if (duration.minutes() > 1) {
            countdown += ' ' + duration.minutes() + ' Minutes'
        } else if (duration.minutes() > 0) {
            countdown += ' 1 Minute'
        }

        if (duration.seconds() > 1) {
            countdown += ' ' + duration.seconds() + ' Seconds'
        } else if (duration.seconds() > 0) {
            countdown += ' 1 Second'
        } else {
            countdown += ' 0 Seconds'
        }
    }

    el.html(countdown);
}

$(function() {
    $('span.countdown').each(function(){
        var elid;
        if ($(this).attr('id')) {
            elid = $(this).attr('id');
        } else {
            elid = 'countdown-' + Math.random().toString(36).substr(2, 9);
            $(this).attr('id',elid);
        }
        setInterval('ew_countdown("'+elid+'")', 1000);
    });
});
