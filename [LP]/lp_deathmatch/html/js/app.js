(function () {
  'use strict';

  var IS_BROWSER = (typeof window.GetParentResourceName === 'undefined');

  var root        = document.getElementById('root');
  var timerEl     = document.getElementById('dmTimer');
  var citiesEl    = document.getElementById('dmCities');
  var resultsEl   = document.getElementById('dmResults');
  var resultsList = document.getElementById('dmResultsList');

  var cityElems = {}; // [cityId] = { card, scoreSpan }
  var scores    = {}; // [cityId] = number, ไว้เทียบว่าใครนำอยู่ (ระบายกรอบทอง)

  function esc(s) {
    return String(s || '')
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function formatTime(ms) {
    var total = Math.max(0, Math.floor(ms / 1000));
    var m = Math.floor(total / 60);
    var s = total % 60;
    function pad(n) { return (n < 10 ? '0' : '') + n; }
    return pad(m) + ':' + pad(s);
  }

  function renderCities(cities) {
    citiesEl.innerHTML = '';
    cityElems = {};
    scores = {};

    for (var i = 0; i < cities.length; i++) {
      var c = cities[i];
      scores[c.id] = Number(c.score) || 0;

      var card = document.createElement('div');
      card.className = 'dm-city';

      var code = document.createElement('div');
      code.className = 'dm-city-code';
      code.textContent = c.code || c.id;
      card.appendChild(code);

      var label = document.createElement('div');
      label.className = 'dm-city-label';
      label.textContent = c.label || '';
      card.appendChild(label);

      var score = document.createElement('div');
      score.className = 'dm-city-score';
      score.textContent = String(scores[c.id]);
      card.appendChild(score);

      citiesEl.appendChild(card);
      cityElems[c.id] = { card: card, scoreSpan: score };
    }

    highlightLeader();
  }

  function highlightLeader() {
    var maxScore = -1;
    for (var id in scores) {
      if (scores[id] > maxScore) maxScore = scores[id];
    }
    for (var id2 in cityElems) {
      cityElems[id2].card.classList.toggle('dm-leading', maxScore > 0 && scores[id2] === maxScore);
    }
  }

  function updateScore(cityId, score) {
    scores[cityId] = Number(score) || 0;
    var entry = cityElems[cityId];
    if (!entry) return;

    entry.scoreSpan.textContent = String(scores[cityId]);
    entry.scoreSpan.classList.remove('dm-pulse');
    // force reflow ให้ browser จำค่าเริ่มต้นก่อนค่อยเล่น animation ใหม่ (ไม่งั้นถ้ายิงรัวๆ animation จะไม่ replay)
    void entry.scoreSpan.offsetWidth;
    entry.scoreSpan.classList.add('dm-pulse');

    highlightLeader();
  }

  function renderResults(cities, groups) {
    resultsList.innerHTML = '';

    for (var i = 0; i < groups.length; i++) {
      var g = groups[i];
      var names = [];
      for (var j = 0; j < g.cities.length; j++) names.push(g.cities[j].label || g.cities[j].code);

      var row = document.createElement('div');
      row.className = 'dm-results-row';

      var rank = document.createElement('span');
      rank.className = 'dm-results-rank';
      rank.textContent = '#' + g.rank;
      row.appendChild(rank);

      var label = document.createElement('span');
      label.textContent = names.join(', ');
      row.appendChild(label);

      var score = document.createElement('span');
      score.className = 'dm-results-score';
      score.textContent = g.score + ' แต้ม';
      row.appendChild(score);

      resultsList.appendChild(row);
    }

    resultsEl.classList.remove('hidden');
  }

  function show() { root.classList.remove('hidden'); }
  function hide() {
    root.classList.add('hidden');
    resultsEl.classList.add('hidden');
  }

  window.addEventListener('message', function (ev) {
    var d = ev.data || {};
    switch (d.action) {
      case 'lp_deathmatch:start':
        resultsEl.classList.add('hidden');
        renderCities(d.cities || []);
        show();
        break;
      case 'lp_deathmatch:tick':
        timerEl.textContent = formatTime(d.remainingMs || 0);
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
      { id: 'valentine', code: 'VLT', label: 'เมืองวาเลนไทน์', score: 3 },
      { id: 'rhodes',    code: 'RHD', label: 'เมืองโรดส์',    score: 5 },
      { id: 'annesburg', code: 'ANB', label: 'เมืองแอนเนสบูร์ก', score: 5 },
    ];

    window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_deathmatch:start', cities: MOCK_CITIES } }));
    window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_deathmatch:tick', remainingMs: 754000 } }));

    // ทดสอบ: /dmpreview_score <cityId> <score>  /dmpreview_end
    window.__lpDeathmatchMock = {
      score: function (cityId, score) {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_deathmatch:scoreUpdate', cityId: cityId, score: score } }));
      },
      end: function () {
        window.dispatchEvent(new MessageEvent('message', {
          data: {
            action: 'lp_deathmatch:end',
            cities: MOCK_CITIES,
            groups: [
              { rank: 1, score: 5, cities: [MOCK_CITIES[1], MOCK_CITIES[2]] },
              { rank: 3, score: 3, cities: [MOCK_CITIES[0]] },
            ],
          },
        }));
      },
    };
  }
})();
