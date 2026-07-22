(function () {
  'use strict';

  var IS_BROWSER = (typeof window.GetParentResourceName === 'undefined');

  var root        = document.getElementById('root');
  var timerEl     = document.getElementById('dmTimer');
  var timerChip   = document.getElementById('dmTimerChip');
  var citiesEl    = document.getElementById('dmCities');
  var resultsEl   = document.getElementById('dmResults');
  var resultsList = document.getElementById('dmResultsList');

  // สีเมือง (ให้ตรงกับ nx_event): วาเลนไทน์ แดง · โรดส์ เขียว · แอนเนสเบิร์ก เหลือง
  var CITY_COLOR = { valentine: '#e0503f', rhodes: '#5bbf6f', annesburg: '#e0b24a' };
  function cityColor(id) { return CITY_COLOR[String(id || '').toLowerCase()] || '#f0ca78'; }

  var cityElems = {}; // [cityId] = { plate, scoreSpan }
  var scores    = {};

  function esc(s) {
    return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }
  function formatTime(ms) {
    var total = Math.max(0, Math.floor(ms / 1000));
    var m = Math.floor(total / 60), s = total % 60;
    function pad(n) { return (n < 10 ? '0' : '') + n; }
    return pad(m) + ':' + pad(s);
  }

  function renderCities(cities) {
    citiesEl.innerHTML = '';
    cityElems = {}; scores = {};

    cities.forEach(function (c) {
      scores[c.id] = Number(c.score) || 0;
      var col = cityColor(c.id);

      var plate = document.createElement('div');
      plate.className = 'plate';
      plate.innerHTML =
        '<div class="inner">' +
          '<span class="title">' + esc(c.label || c.code || c.id) + '</span>' +
          '<div class="teambar" style="--tc:' + col + '"></div>' +
          '<div class="score" style="--tc:' + col + '">' + scores[c.id] + '<small>แต้ม</small></div>' +
        '</div>';
      citiesEl.appendChild(plate);
      cityElems[c.id] = { plate: plate, scoreSpan: plate.querySelector('.score') };
    });

    highlightLeader();
  }

  function highlightLeader() {
    var maxScore = -1;
    for (var id in scores) if (scores[id] > maxScore) maxScore = scores[id];
    for (var id2 in cityElems) {
      cityElems[id2].plate.classList.toggle('dm-leading', maxScore > 0 && scores[id2] === maxScore);
    }
  }

  function updateScore(cityId, score) {
    scores[cityId] = Number(score) || 0;
    var entry = cityElems[cityId];
    if (!entry) return;
    entry.scoreSpan.innerHTML = scores[cityId] + '<small>แต้ม</small>';
    entry.scoreSpan.classList.remove('dm-pulse');
    void entry.scoreSpan.offsetWidth; // reflow เพื่อ replay animation
    entry.scoreSpan.classList.add('dm-pulse');
    highlightLeader();
  }

  function renderResults(cities, groups) {
    resultsList.innerHTML = '';
    groups.forEach(function (g) {
      var names = g.cities.map(function (c) { return c.label || c.code; });
      var row = document.createElement('div');
      row.className = 'dm-results-row';
      row.innerHTML = '<span class="dm-results-rank">#' + g.rank + '</span>' +
                      '<span>' + esc(names.join(', ')) + '</span>' +
                      '<span class="dm-results-score">' + g.score + ' แต้ม</span>';
      resultsList.appendChild(row);
    });
    resultsEl.classList.remove('hidden');
  }

  function show() { root.classList.remove('hidden'); }
  function hide() { root.classList.add('hidden'); resultsEl.classList.add('hidden'); }

  window.addEventListener('message', function (ev) {
    var d = ev.data || {};
    switch (d.action) {
      case 'lp_deathmatch:start':
        resultsEl.classList.add('hidden');
        renderCities(d.cities || []);
        show();
        break;
      case 'lp_deathmatch:tick':
        var ms = d.remainingMs || 0;
        timerEl.textContent = formatTime(ms);
        if (timerChip) timerChip.classList.toggle('warn', ms <= 60000);
        break;
      case 'lp_deathmatch:scoreUpdate':
        updateScore(d.cityId, d.score);
        break;
      case 'lp_deathmatch:end':
        renderResults(d.cities || [], d.groups || []);
        break;
      case 'lp_deathmatch:hide':
        hide();
        break;
    }
  });

  /* ---------------- DEV ONLY (browser preview) ---------------- */
  if (IS_BROWSER) {
    var MOCK_CITIES = [
      { id: 'valentine', code: 'VLT', label: 'วาเลนไทน์',    score: 3 },
      { id: 'rhodes',    code: 'RHD', label: 'โรดส์',        score: 5 },
      { id: 'annesburg', code: 'ANB', label: 'แอนเนสเบิร์ก', score: 5 },
    ];
    window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_deathmatch:start', cities: MOCK_CITIES } }));
    window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_deathmatch:tick', remainingMs: 754000 } }));
    window.__lpDeathmatchMock = {
      score: function (cityId, score) { window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_deathmatch:scoreUpdate', cityId: cityId, score: score } })); },
      end: function () {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_deathmatch:end', cities: MOCK_CITIES,
          groups: [ { rank: 1, score: 5, cities: [MOCK_CITIES[1], MOCK_CITIES[2]] }, { rank: 3, score: 3, cities: [MOCK_CITIES[0]] } ] } }));
      },
    };
  }
})();
