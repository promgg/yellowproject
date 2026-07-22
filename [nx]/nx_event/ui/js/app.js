/* jshint esversion: 6 */
(function () {
    'use strict';

    var el = function (id) { return document.getElementById(id); };
    var dom = {
        hud:       el('event-hud'),
        cityRow:   el('cityRow'),
        boxStrip:  el('boxStrip'),
        boxCount:  el('boxCount'),
        timerChip: el('timerChip'),
        timer:     el('timer-value'),
        downed:    el('downed-overlay'),
        result:    el('result-panel'),
        resultList:el('result-list'),
    };

    var I_PPL = '<svg viewBox="0 0 16 16" fill="currentColor"><circle cx="8" cy="5" r="3"/><path d="M2 15a6 6 0 0112 0z"/></svg>';

    var totalBoxes  = 5;
    var timerHandle = null;
    var secondsLeft = 0;

    function show(e) { e.classList.remove('hidden'); }
    function hide(e) { e.classList.add('hidden'); }
    function escHtml(s) {
        return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }
    function cityColor(c) {
        // color = { r, g, b } จาก nx_cityselect
        if (c && typeof c === 'object') return 'rgb(' + (c.r|0) + ',' + (c.g|0) + ',' + (c.b|0) + ')';
        return '#888';
    }

    // ── Timer (client-side นับถอยหลังจาก duration) ──────────────────────────
    function startTimer(seconds) {
        clearInterval(timerHandle);
        secondsLeft = Math.max(0, seconds | 0);
        renderTimer();
        timerHandle = setInterval(function () {
            secondsLeft = Math.max(0, secondsLeft - 1);
            renderTimer();
        }, 1000);
    }
    function renderTimer() {
        var m = String(Math.floor(secondsLeft / 60)).padStart(2, '0');
        var s = String(secondsLeft % 60).padStart(2, '0');
        if (dom.timer) dom.timer.textContent = m + ':' + s;
        if (dom.timerChip) dom.timerChip.classList.toggle('warn', secondsLeft <= 60);
    }

    // ── Render nameplate เมือง + แถบกล่องรวม ────────────────────────────────
    function renderCities(snapshot) {
        if (!Array.isArray(snapshot)) return;

        // การ์ดเมือง: ชื่อ + แถบสีเมือง + จำนวนคน (count/max)
        dom.cityRow.innerHTML = snapshot.map(function (c) {
            var col = cityColor(c.color);
            return '<div class="plate"><div class="inner">' +
                   '<span class="title">' + escHtml(c.label) + '</span>' +
                   '<div class="teambar" style="--tc:' + col + '"></div>' +
                   '<div class="ppl" style="--tc:' + col + '">' + I_PPL + (c.count || 0) + '/' + (c.maxCount || 0) + '</div>' +
                   '</div></div>';
        }).join('');

        // แถบกล่องรวม (total ช่อง) — ติดสีเมืองตามจำนวนกล่องที่เมืองนั้นเก็บได้
        var filled = 0, slots = '';
        snapshot.forEach(function (c) {
            var col = cityColor(c.color);
            var n = c.boxes || 0;
            for (var i = 0; i < n && filled < totalBoxes; i++) {
                slots += '<span class="box on" style="--tc:' + col + '"></span>';
                filled++;
            }
        });
        for (var j = filled; j < totalBoxes; j++) slots += '<span class="box"></span>';
        dom.boxStrip.innerHTML = slots;
        dom.boxCount.textContent = filled + '/' + totalBoxes;
    }

    // ── Result panel (คงเดิม) ───────────────────────────────────────────────
    function showResult(data) {
        clearInterval(timerHandle);
        hide(dom.hud);
        hide(dom.downed);
        dom.resultList.innerHTML = '';
        (data || []).forEach(function (c) {
            var col = cityColor(c.color);
            dom.resultList.innerHTML +=
                '<div class="result-row"><span class="result-city-name" style="color:' + col + '">' + escHtml(c.label) + '</span>' +
                '<span class="result-boxes-val" style="color:' + col + '">' + (c.boxes || 0) + ' กล่อง</span></div>';
        });
        show(dom.result);
        setTimeout(function () { hide(dom.result); }, 9000);
    }

    // ── Message handler (protocol เดิม) ─────────────────────────────────────
    window.addEventListener('message', function (e) {
        var msg = e.data;
        if (!msg || !msg.action) return;
        switch (msg.action) {
            case 'SHOW':
                totalBoxes = msg.total || 5;
                show(dom.hud);
                hide(dom.result);
                startTimer(msg.duration || 600);
                if (msg.snapshot) renderCities(msg.snapshot);
                break;
            case 'HIDE':
                hide(dom.hud);
                clearInterval(timerHandle);
                break;
            case 'UPDATE_HUD':
                if (msg.data) renderCities(msg.data);
                break;
            case 'SHOW_RESULT':
                showResult(msg.data);
                break;
            case 'PLAYER_DOWNED':
                show(dom.downed);
                break;
            case 'PLAYER_ALIVE':
                hide(dom.downed);
                break;
        }
    });
})();
