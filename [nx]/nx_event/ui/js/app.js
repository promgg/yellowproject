/* jshint esversion: 6 */
(function () {
    'use strict';

    // ── DOM refs ────────────────────────────────────────────────────────────
    const el = id => document.getElementById(id);

    const dom = {
        hud:          el('event-hud'),
        timer:        el('timer-value'),
        boxesFill:    el('boxes-fill'),
        boxesCount:   el('boxes-count'),
        cityList:     el('city-list'),
        downed:       el('downed-overlay'),
        result:       el('result-panel'),
        resultList:   el('result-list'),
    };

    // ── State ───────────────────────────────────────────────────────────────
    let totalBoxes    = 5;
    let timerHandle   = null;
    let secondsLeft   = 0;

    // ── Utility ─────────────────────────────────────────────────────────────
    function show(elem)  { elem.classList.remove('hidden'); }
    function hide(elem)  { elem.classList.add('hidden'); }
    function rgba(c, a)  {
        if (!c) return '#888';
        return `rgba(${c.r},${c.g},${c.b},${a !== undefined ? a : 0.9})`;
    }

    // ── Timer ───────────────────────────────────────────────────────────────
    function startTimer(seconds) {
        clearInterval(timerHandle);
        secondsLeft = seconds;
        renderTimer();
        timerHandle = setInterval(() => {
            secondsLeft = Math.max(0, secondsLeft - 1);
            renderTimer();
        }, 1000);
    }

    function renderTimer() {
        const m = String(Math.floor(secondsLeft / 60)).padStart(2, '0');
        const s = String(secondsLeft % 60).padStart(2, '0');
        dom.timer.textContent = `${m}:${s}`;
    }

    // ── City list ───────────────────────────────────────────────────────────
    function renderCities(snapshot) {
        dom.cityList.innerHTML = '';

        // Recalculate total collected boxes from snapshot
        const totalCollected = snapshot.reduce((acc, c) => acc + (c.boxes || 0), 0);
        const pct = totalBoxes > 0 ? (totalCollected / totalBoxes * 100) : 0;
        dom.boxesFill.style.width  = pct + '%';
        dom.boxesCount.textContent = `${totalCollected}/${totalBoxes}`;

        snapshot.forEach(city => {
            const row = document.createElement('div');
            row.className = 'city-row';

            const dotColor = rgba(city.color);

            row.innerHTML = `
                <div class="city-dot" style="background:${dotColor};color:${dotColor}"></div>
                <div class="city-name">${escHtml(city.label)}</div>
                <div class="city-stats">
                    <span class="city-box-badge">📦 ${city.boxes}</span>
                    <span class="city-people">${city.count}/${city.maxCount}</span>
                </div>
            `;
            dom.cityList.appendChild(row);
        });
    }

    // ── Result panel ────────────────────────────────────────────────────────
    function showResult(data) {
        clearInterval(timerHandle);
        hide(dom.hud);
        hide(dom.downed);

        dom.resultList.innerHTML = '';

        (data || []).forEach(c => {
            const row = document.createElement('div');
            row.className = 'result-row';
            const color = rgba(c.color);
            row.innerHTML = `
                <span class="result-city-name" style="color:${color}">${escHtml(c.label)}</span>
                <span class="result-boxes-val" style="color:${color}">${c.boxes} กล่อง</span>
            `;
            dom.resultList.appendChild(row);
        });

        show(dom.result);
        setTimeout(() => hide(dom.result), 9000);
    }

    // ── Safety: escape HTML ─────────────────────────────────────────────────
    function escHtml(str) {
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    // ── Message handler ─────────────────────────────────────────────────────
    window.addEventListener('message', function (e) {
        const msg = e.data;
        if (!msg || !msg.action) return;

        switch (msg.action) {

            // ── Show HUD + start timer ──────────────────────────────────
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

            // ── Update city list ────────────────────────────────────────
            case 'UPDATE_HUD':
                if (msg.data) renderCities(msg.data);
                break;

            // ── Event ended ─────────────────────────────────────────────
            case 'SHOW_RESULT':
                showResult(msg.data);
                break;

            // ── Player downed / alive ─────────────────────────────────────
            case 'PLAYER_DOWNED':
                show(dom.downed);
                break;

            case 'PLAYER_ALIVE':
                hide(dom.downed);
                break;
        }
    });

})();
