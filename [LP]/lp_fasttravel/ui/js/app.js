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
    stopAirdropTimer();
    hideUI();
  }

  function confirmTravel(stationId) {
    post('confirmTravel', { stationId: stationId });
    stopAirdropTimer();
    hideUI();
  }

  // ── ปุ่มแอร์ดรอปบนหัวเมนู ──
  // ตัวจับเวลาเดินฝั่ง NUI จากค่าที่ server ส่งมาตอนเปิดเมนู ไม่ได้ถาม server ซ้ำทุกวินาที
  // เมนูเปิดอยู่แค่ไม่กี่วินาที ความคลาดเคลื่อนจึงไม่มีนัยสำคัญ และ server ตรวจซ้ำตอนกดอยู่แล้ว
  var _airdropTimer = null;

  function stopAirdropTimer() {
    if (_airdropTimer) { clearInterval(_airdropTimer); _airdropTimer = null; }
  }

  function fmtClock(ms) {
    var total = Math.max(0, Math.floor(ms / 1000));
    var m = Math.floor(total / 60);
    var s = total % 60;
    return m + ':' + (s < 10 ? '0' : '') + s;
  }

  function renderAirdrop(ad) {
    var slot = document.getElementById('airdrop-slot');
    stopAirdropTimer();
    slot.innerHTML = '';

    // สถานีนี้ไม่มีทีมแอร์ดรอป (Emerald / Riggs) — ไม่ต้องมีปุ่ม
    if (!ad) { slot.classList.add('hidden'); return; }
    slot.classList.remove('hidden');

    var pill = document.createElement('div');
    pill.className = 'airdrop-pill';

    var label = document.createElement('div');
    label.className = 'airdrop-label';
    var strong = document.createElement('strong');
    strong.textContent = 'แอร์ดรอป';
    var sub = document.createElement('span');
    sub.textContent = ad.teamLabel || '';
    label.appendChild(strong);
    label.appendChild(sub);
    pill.appendChild(label);

    var timer = null;
    if (ad.state === 'open' && ad.remainingMs > 0) {
      timer = document.createElement('div');
      timer.className = 'airdrop-timer';
      timer.textContent = fmtClock(ad.remainingMs);
      pill.appendChild(timer);
    }

    var btn = document.createElement('button');
    btn.className = 'airdrop-btn';

    var texts = {
      open:   'เข้าร่วม',
      locked: 'หมดเวลาเข้าร่วม',
      joined: 'เข้าร่วมแล้ว',
      closed: 'ยังไม่เปิดรอบ'
    };
    btn.textContent = texts[ad.state] || texts.closed;

    if (ad.state === 'open') {
      btn.addEventListener('click', function () {
        post('joinAirdrop', { stationId: ad.stationId });
        hideUI();
      });
    } else {
      btn.disabled = true;
      btn.classList.add('disabled');
    }
    pill.appendChild(btn);
    slot.appendChild(pill);

    if (timer) {
      var endAt = Date.now() + ad.remainingMs;
      _airdropTimer = setInterval(function () {
        var left = endAt - Date.now();
        if (left <= 0) {
          // หมดเวลาระหว่างเมนูเปิดค้างอยู่ — ปิดปุ่มทันที ไม่ให้กดแล้วเจอ error เปล่าๆ
          stopAirdropTimer();
          timer.remove();
          btn.textContent = texts.locked;
          btn.disabled = true;
          btn.classList.add('disabled');
          return;
        }
        timer.textContent = fmtClock(left);
      }, 1000);
    }
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
        renderAirdrop(data.airdrop || null);
        renderStations(data.stations || [], data.cooldown || 0);
        showUI();
        break;
      case 'closeMenu':
        stopAirdropTimer(); // ไม่ปล่อยให้ interval เดินต่อหลังปิดเมนู
        hideUI();
        break;
    }
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeMenu();
  });

})();
