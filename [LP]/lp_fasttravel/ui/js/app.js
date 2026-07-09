/* jshint esversion: 6 */
(function () {
  'use strict';

  var _resourceName = (function () {
    try { return window.GetParentResourceName(); } catch (e) { return 'lp_fasttravel'; }
  })();

  function post(endpoint, body) {
    fetch('https://' + _resourceName + '/' + endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {})
    }).catch(function () {});
  }

  function showUI() { document.getElementById('root').classList.remove('hidden'); }
  function hideUI() { document.getElementById('root').classList.add('hidden'); }

  function closeMenu() {
    post('closeMenu');
    hideUI();
  }

  function confirmTravel(stationId) {
    post('confirmTravel', { stationId: stationId });
    hideUI();
  }

  function renderCooldown(seconds) {
    var el = document.getElementById('cooldown-banner');
    if (seconds > 0) {
      el.textContent = 'กรุณารออีก ' + seconds + ' วินาที ก่อนเดินทางครั้งถัดไป';
      el.classList.remove('hidden');
    } else {
      el.classList.add('hidden');
    }
  }

  function renderStations(stations, cooldown) {
    var grid = document.getElementById('station-grid');
    grid.innerHTML = '';

    stations.forEach(function (st) {
      var card = document.createElement('div');
      card.className = 'station-card';

      // รูปเด่นเต็มความกว้างด้านบนของการ์ด
      var image = document.createElement('div');
      image.className = 'card-image';
      if (st.image) {
        image.style.backgroundImage = 'url(' + st.image + ')';
      } else {
        image.style.background = 'linear-gradient(160deg, ' + (st.color || '#333') + ' 0%, rgba(19,19,19,0.9) 100%)';
      }
      card.appendChild(image);

      // เนื้อหา: ชื่อ / คำอธิบาย / สถิติ
      var body = document.createElement('div');
      body.className = 'card-body';

      var title = document.createElement('div');
      title.className = 'card-title';
      title.textContent = st.name;
      body.appendChild(title);

      var desc = document.createElement('div');
      desc.className = 'card-desc';
      desc.textContent = st.description || '';
      body.appendChild(desc);

      if (!st.isCurrent) {
        var stats = document.createElement('div');
        stats.className = 'card-stats';
        stats.innerHTML =
          '<div class="stat-row"><span>ระยะทาง</span><span class="stat-val">' + st.distanceKm.toFixed(2) + ' KM</span></div>' +
          '<div class="stat-row"><span>ค่าเดินทาง</span><span class="stat-val gold">$' + st.price + '</span></div>';
        body.appendChild(stats);
      }

      card.appendChild(body);

      // ปุ่ม/label เต็มความกว้างชิดขอบล่างสุดของการ์ด
      if (st.isCurrent) {
        var cur = document.createElement('div');
        cur.className = 'current-label';
        cur.textContent = 'สถานีปัจจุบัน';
        card.appendChild(cur);
      } else {
        var btn = document.createElement('button');
        btn.className = 'confirm-btn';
        btn.textContent = 'Confirm Travel';
        if (cooldown > 0) {
          btn.disabled = true;
          btn.classList.add('disabled');
        }
        btn.addEventListener('click', function () { confirmTravel(st.id); });
        card.appendChild(btn);
      }

      grid.appendChild(card);
    });
  }

  window.addEventListener('message', function (e) {
    var data = e.data;
    if (!data || !data.type) return;

    switch (data.type) {
      case 'openMenu':
        renderCooldown(data.cooldown || 0);
        renderStations(data.stations || [], data.cooldown || 0);
        showUI();
        break;
      case 'closeMenu':
        hideUI();
        break;
    }
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeMenu();
  });

})();
