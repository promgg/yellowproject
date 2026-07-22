(function () {
    'use strict';

    var panel = document.getElementById('cooldownPanel');
    var timer = document.getElementById('cooldown');
    var progressRing = document.getElementById('progressRing');
    var ringLength = 125.664;
    var initialSeconds = 0;

    function toSeconds(value) {
        var seconds = Number(value);
        if (!Number.isFinite(seconds)) return 0;
        return Math.max(0, Math.floor(seconds));
    }

    function pad(value) {
        return value < 10 ? '0' + value : String(value);
    }

    function formatTime(totalSeconds) {
        var minutes = Math.floor(totalSeconds / 60);
        var seconds = totalSeconds % 60;
        return pad(minutes) + ':' + pad(seconds);
    }

    function renderTime(totalSeconds) {
        if (initialSeconds <= 0 || totalSeconds > initialSeconds) {
            initialSeconds = Math.max(1, totalSeconds);
        }

        var ratio = Math.min(1, totalSeconds / initialSeconds);
        var display = formatTime(totalSeconds);
        timer.textContent = display;
        timer.setAttribute('datetime', 'PT' + totalSeconds + 'S');
        progressRing.style.strokeDashoffset = String(ringLength * (1 - ratio));
    }

    function show(totalSeconds) {
        renderTime(totalSeconds);
        panel.classList.add('is-visible');
        panel.setAttribute('aria-hidden', 'false');
    }

    function hide() {
        panel.classList.remove('is-visible');
        panel.setAttribute('aria-hidden', 'true');
        initialSeconds = 0;
    }

    window.addEventListener('message', function (event) {
        var data = event.data || {};

        if (data.type === 'Show') {
            show(toSeconds(data.time));
        } else if (data.type === 'Hide') {
            hide();
        }
    });
}());
