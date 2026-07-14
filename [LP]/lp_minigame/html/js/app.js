(function () {
  var App        = document.getElementById('app');
  var DotsEl     = document.getElementById('dots');
  var BodySpace  = document.getElementById('body-spacebar');
  var BodySeq    = document.getElementById('body-sequence');
  var SbFill     = document.getElementById('sb-fill');
  var SbZone     = document.getElementById('sb-zone');
  var SeqKeys    = document.getElementById('seq-keys');
  var SeqFill    = document.getElementById('seq-fill');
  var BodyFish   = document.getElementById('body-fishing');
  var FishZone   = document.getElementById('fish-zone');
  var FishInd    = document.getElementById('fish-indicator');
  var BodyCircle = document.getElementById('body-circle');
  var CircleZone = document.getElementById('circle-zone');
  var CirclePtr  = document.getElementById('circle-pointer');
  var CircleKey  = document.getElementById('circle-key');
  var BodyLock     = document.getElementById('body-lockpick');
  var LockWrap     = document.getElementById('lock-wrap');
  var LockCylinder = document.getElementById('lock-cylinder');
  var LockDriver   = document.getElementById('lock-driver');
  var LockPinWrap  = document.getElementById('lock-pin-wrap');
  var LockPins     = document.getElementById('lock-pins');

  var KEYCODE = { 32: 'SPACE', 87: 'W', 65: 'A', 83: 'S', 68: 'D', 69: 'E' };
  var PUSH_KEYS = { 87: 1, 65: 1, 83: 1, 68: 1, 37: 1, 39: 1 }; // W A S D ← →

  var G = null;
  var raf = null;
  var roundActive = false;
  var sb = null;
  var seq = null;
  var fish = null;
  var circle = null;
  var lock = null;

  function post(name, data) {
    var resourceName = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'lp_minigame';
    fetch('https://' + resourceName + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {}),
    }).catch(function () {});
  }

  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
  function cancelRaf() {
    if (raf) { cancelAnimationFrame(raf); raf = null; }
    if (lock && lock.cylInterval) { clearInterval(lock.cylInterval); lock.cylInterval = null; }
  }
  function show(el) { el.classList.remove('hidden'); }
  function hide(el) { el.classList.add('hidden'); }
  // เคลียร์ทุก body ก่อนโชว์อันที่ต้องการเสมอ กันเคสค้างจากรอบ/โหมดก่อนหน้า
  function hideAllBodies() { hide(BodySpace); hide(BodySeq); hide(BodyFish); hide(BodyCircle); hide(BodyLock); }

  function renderDots(need, done) {
    DotsEl.innerHTML = '';
    for (var i = 0; i < need; i++) {
      var d = document.createElement('span');
      d.className = 'lmg-dot' + (i < done ? ' lmg-on' : '');
      DotsEl.appendChild(d);
    }
  }

  // ── lifecycle ──────────────────────────────────────────────────────────
  function openGame(kind, cfg) {
    G = {
      kind: kind,
      cfg: cfg,
      need: cfg.successNeeded || 3,
      failLimit: cfg.failLimit || 0,
      success: 0,
      fail: 0,
    };
    // lockpick มีตัวนับ pin ของตัวเอง ไม่ใช้ dots รวม
    DotsEl.style.display = (kind === 'lockpick') ? 'none' : '';
    renderDots(G.need, 0);
    show(App);
    nextRound();
  }

  function finish(win) {
    cancelRaf();
    roundActive = false;
    hide(App);
    post('lp_minigame:finish', { success: !!win });
    G = null; sb = null; seq = null; fish = null; circle = null; lock = null;
  }

  function closeGame() {
    cancelRaf();
    roundActive = false;
    hide(App);
    G = null; sb = null; seq = null; fish = null; circle = null; lock = null;
  }

  function roundResult(ok) {
    if (!G || !roundActive) return;
    roundActive = false;
    cancelRaf();

    if (ok) {
      G.success++;
      renderDots(G.need, G.success);
      if (G.success >= G.need) return finish(true);
    } else {
      G.fail++;
      if (G.failLimit > 0 && G.fail >= G.failLimit) {
        setTimeout(function () { finish(false); }, 220);
        return;
      }
    }
    setTimeout(nextRound, 350);
  }

  function nextRound() {
    if (!G) return;
    if (G.kind === 'spacebar') startSpacebar();
    else if (G.kind === 'fishing') startFishing();
    else if (G.kind === 'circle') startCircle();
    else if (G.kind === 'lockpick') startLockpick();
    else startSequence();
  }

  // ── spacebar ───────────────────────────────────────────────────────────
  function startSpacebar() {
    hideAllBodies();
    show(BodySpace);

    var cfg = G.cfg;
    var diff = clamp(cfg.difficulty || 5, 1, 10);
    var trackW = SbZone.parentElement.clientWidth;
    var zonePx = cfg.zoneSize || (35 - (diff - 1) * (35 - 15) / 9);
    var minPx = trackW * 0.45;
    var maxPx = trackW * 0.96 - zonePx;
    var startPx = minPx + Math.random() * Math.max(0, maxPx - minPx);

    sb = { startPx: startPx, zonePx: zonePx, trackW: trackW, duration: cfg.duration || 2000, t0: null, pct: 0 };

    SbZone.style.left = startPx + 'px';
    SbZone.style.width = zonePx + 'px';
    SbFill.style.width = '0%';

    roundActive = true;
    cancelRaf();

    var step = function (ts) {
      if (!roundActive) return;
      if (sb.t0 === null) sb.t0 = ts;
      var p = clamp((ts - sb.t0) / sb.duration, 0, 1);
      sb.pct = p * 100;
      SbFill.style.width = sb.pct + '%';
      if (p >= 1) return roundResult(false);
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
  }

  function spacebarPress() {
    if (!sb || !roundActive) return;
    var edgePx = (sb.pct / 100) * sb.trackW;
    var ok = edgePx >= sb.startPx && edgePx <= (sb.startPx + sb.zonePx);
    roundResult(ok);
  }

  // ── sequence ───────────────────────────────────────────────────────────
  function startSequence() {
    hideAllBodies();
    show(BodySeq);

    var cfg = G.cfg;
    var n = cfg.keys || 6;
    var pool = (cfg.pool && cfg.pool.length) ? cfg.pool : ['W', 'A', 'S', 'D'];
    var list = [];
    for (var i = 0; i < n; i++) list.push(pool[Math.floor(Math.random() * pool.length)]);

    seq = { list: list, idx: 0, duration: cfg.timePerSet || 4000, t0: null };

    SeqKeys.innerHTML = '';
    list.forEach(function (k, idx) {
      var b = document.createElement('div');
      b.className = 'lmg-key' + (idx === 0 ? ' lmg-active' : '');
      b.textContent = k;
      SeqKeys.appendChild(b);
    });
    SeqFill.style.width = '100%';

    roundActive = true;
    cancelRaf();

    var step = function (ts) {
      if (!roundActive) return;
      if (seq.t0 === null) seq.t0 = ts;
      var p = clamp((ts - seq.t0) / seq.duration, 0, 1);
      SeqFill.style.width = ((1 - p) * 100) + '%';
      if (p >= 1) return roundResult(false);
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
  }

  function sequencePress(letter) {
    if (!seq || !roundActive) return;
    var boxes = SeqKeys.children;
    if (letter === seq.list[seq.idx]) {
      boxes[seq.idx].classList.remove('lmg-active');
      boxes[seq.idx].classList.add('lmg-done');
      seq.idx++;
      if (seq.idx >= seq.list.length) return roundResult(true);
      boxes[seq.idx].classList.add('lmg-active');
    } else {
      boxes[seq.idx].classList.add('lmg-wrong');
      roundResult(false);
    }
  }

  // ── fishing (ย้ายมาจาก MJ-AfkFishing) ────────────────────────────────────
  // indicator เด้งขึ้นลงต่อเนื่อง (ไม่ใช่วิ่งเส้นตรงแบบ spacebar) — กด E ตอนอยู่ในโซนจับ
  // ต้นฉบับไม่มี timeout เลย แต่ที่นี่บล็อก NUI focus ทั้งจอไว้ระหว่างเล่น เลยเพิ่ม duration กัน soft-lock
  function randSpeed(min, max) { return min + Math.random() * (max - min); }

  function startFishing() {
    hideAllBodies();
    show(BodyFish);

    var cfg = G.cfg;
    // ค่า config เดิมกำหนดเป็น %/100ms (เข้ากับ setInterval เก่า) — คูณ 10 แปลงเป็น %/วินาที ให้ใช้กับ rAF delta-time ได้
    // ผลลัพธ์ความเร็วภาพเท่าเดิมทุกประการ แค่เปลี่ยนกลไกขับเคลื่อนจาก step กระโดดทุก 100ms เป็นวาดต่อเนื่องทุกเฟรม (60fps)
    var speedMin = (cfg.speedMin || 1.5) * 10;
    var speedMax = (cfg.speedMax || 2.5) * 10;
    var zoneSize = cfg.zoneSize || 15;
    var zoneStart = 5 + Math.random() * (95 - zoneSize - 5);
    var zoneEnd   = zoneStart + zoneSize;

    fish = {
      pos: Math.random() * 30,
      dir: 1,
      speed: randSpeed(speedMin, speedMax),
      zoneStart: zoneStart,
      zoneEnd: zoneEnd,
      duration: cfg.duration || 8000,
      elapsed: 0,
      t0: null,
    };

    FishZone.style.top    = zoneStart + '%';
    FishZone.style.height = zoneSize + '%';
    FishInd.style.top     = fish.pos + '%';

    roundActive = true;
    cancelRaf();

    var step = function (ts) {
      if (!roundActive) return;
      if (fish.t0 === null) fish.t0 = ts;
      var dt = (ts - fish.t0) / 1000; // วินาทีนับจากเฟรมก่อนหน้า
      fish.t0 = ts;

      fish.pos += fish.dir * fish.speed * dt;
      if (fish.pos >= 95) {
        fish.pos = 95; fish.dir = -1; fish.speed = randSpeed(speedMin, speedMax);
      } else if (fish.pos <= 0) {
        fish.pos = 0; fish.dir = 1; fish.speed = randSpeed(speedMin, speedMax);
      }
      FishInd.style.top = fish.pos + '%';

      fish.elapsed += dt * 1000;
      if (fish.elapsed >= fish.duration) return roundResult(false); // หมดเวลา = พลาด
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
  }

  function fishingPress() {
    if (!fish || !roundActive) return;
    var ok = fish.pos >= fish.zoneStart && fish.pos <= fish.zoneEnd;
    roundResult(ok);
  }

  // ── circle (skill-check วงแหวน) ──────────────────────────────────────────
  // เข็มหมุนรอบวงต่อเนื่อง กดปุ่มที่โชว์ตรงกลางตอนเข็มเข้าโซนทอง
  // มุมทุกตัววัดเป็นองศา "ตามเข็มนาฬิกาจากบนสุด (12 นาฬิกา)" ให้ตรงกับ transform rotate ของ SVG
  var CIRCLE_R = 40;

  function polar(deg, r) {
    var rad = deg * Math.PI / 180;
    return { x: 50 + r * Math.sin(rad), y: 50 - r * Math.cos(rad) };
  }

  function circleZonePath(startDeg, arcDeg) {
    var a = polar(startDeg, CIRCLE_R);
    var b = polar(startDeg + arcDeg, CIRCLE_R);
    var large = arcDeg > 180 ? 1 : 0;
    return 'M ' + a.x.toFixed(2) + ' ' + a.y.toFixed(2) +
           ' A ' + CIRCLE_R + ' ' + CIRCLE_R + ' 0 ' + large + ' 1 ' +
           b.x.toFixed(2) + ' ' + b.y.toFixed(2);
  }

  function inArc(pointerDeg, startDeg, arcDeg) {
    var d = (((pointerDeg - startDeg) % 360) + 360) % 360;
    return d <= arcDeg;
  }

  function startCircle() {
    hideAllBodies();
    show(BodyCircle);

    var cfg = G.cfg;
    var diff = clamp(cfg.difficulty || 5, 1, 10);
    // difficulty 1->10 : โซน 70°->28°, เข็มหมุนครบรอบ 1600ms->850ms (เร็วขึ้น = ยากขึ้น)
    var arcDeg   = cfg.arcDeg   || (70 - (diff - 1) * (70 - 28) / 9);
    var rotateMs = cfg.rotateMs || (1600 - (diff - 1) * (1600 - 850) / 9);
    var startDeg = Math.random() * 360;

    var pool = (cfg.pool && cfg.pool.length) ? cfg.pool : ['E'];
    var key  = pool[Math.floor(Math.random() * pool.length)];

    circle = {
      startDeg: startDeg, arcDeg: arcDeg, rotateMs: rotateMs,
      key: key, pool: pool, duration: cfg.duration || 4000, t0: null,
    };

    CircleZone.setAttribute('d', circleZonePath(startDeg, arcDeg));
    CircleZone.classList.remove('lmg-hit', 'lmg-miss');
    CircleKey.textContent = key === 'SPACE' ? '␣' : key;
    CirclePtr.setAttribute('transform', 'rotate(0 50 50)');

    roundActive = true;
    cancelRaf();

    var step = function (ts) {
      if (!roundActive) return;
      if (circle.t0 === null) circle.t0 = ts;
      var elapsed = ts - circle.t0;
      var deg = (elapsed / circle.rotateMs) * 360;
      CirclePtr.setAttribute('transform', 'rotate(' + (deg % 360).toFixed(2) + ' 50 50)');
      if (elapsed >= circle.duration) return roundResult(false);
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
  }

  function circlePress(letter) {
    if (!circle || !roundActive) return;
    if (circle.pool.indexOf(letter) === -1) return; // ปุ่มนอก pool (เช่น E ที่ค้างมาจากตอนกด hold เปิดมินิเกม) เมิน ไม่นับว่าพลาด
    if (letter !== circle.key) return roundResult(false); // กดผิดปุ่ม (แต่อยู่ใน pool) = พลาด
    var elapsed = circle.t0 === null ? 0 : (performance.now() - circle.t0);
    var deg = (elapsed / circle.rotateMs) * 360;
    var ok = inArc(deg, circle.startDeg, circle.arcDeg);
    CircleZone.classList.add(ok ? 'lmg-hit' : 'lmg-miss');
    roundResult(ok);
  }

  // ── lockpick (port จาก guf1ck/lockpick-system วาดใหม่ SVG/CSS) ───────────
  // เมาส์เล็ง pick หา solveDeg ที่ซ่อน (−90..90) → กด W/A/S/D/←/→ ค้างเพื่อหมุนกระบอก
  // เล็งตรงโซน (±solvePadding) → กระบอกหมุนถึงสุด = ปลด; เพี้ยน → กระบอกติด ดัน pin เสียหาย/หัก
  var LP_MAXROT = 90, LP_MOUSE_SMOOTH = 2, LP_CYL_SPEED = 3, LP_DMG_INTERVAL = 150, LP_MAXDIST = 45;

  // เหล็กงัด (pinTop+pinBott) หมุนตามมุมเล็ง (pinRot) เท่านั้น — คุมด้วยเมาส์
  // ตำแหน่ง/transform-origin กำหนดใน CSS ตรงตามต้นฉบับแล้ว เหลือแค่ rotate() เดี่ยว ๆ
  function lpSetPick() {
    if (!lock) return;
    LockPinWrap.style.transform = 'rotate(' + lock.pinRot.toFixed(2) + 'deg)';
  }
  // cylinder + driver หมุนพร้อมกันด้วยมุมกระบอกเดียวกัน (cylRot) — คุมด้วย W/A/S/D ค้าง,
  // อิสระจากมุมเล็งของเหล็กงัด (ตรงกับต้นฉบับที่ cyl กับ driver รับ rotateZ เดียวกันเป๊ะ)
  function lpSetCyl() {
    if (!lock) return;
    var t = 'rotate(' + lock.cylRot.toFixed(2) + 'deg)';
    LockCylinder.style.transform = t;
    LockDriver.style.transform   = t;
  }

  function lpRenderPins() {
    LockPins.innerHTML = '';
    for (var i = 0; i < lock.pinsTotal; i++) {
      var p = document.createElement('span');
      var broken = i < (lock.pinsTotal - lock.pins);
      p.className = 'lmg-lock-pin' + (broken ? ' lmg-broken' : '');
      LockPins.appendChild(p);
    }
  }

  function startLockpick() {
    hideAllBodies();
    show(BodyLock);
    cancelRaf();

    var cfg = G.cfg;
    var diff = clamp(cfg.difficulty || 5, 1, 10);
    var pins = cfg.pins || 5;

    lock = {
      solveDeg: Math.random() * 180 - 90,
      solvePadding: cfg.solvePadding || (8 - (diff - 1) * (8 - 2) / 9),
      pinDamage: cfg.pinDamage || (12 + (diff - 1) * (34 - 12) / 9),
      pinRot: 0, cylRot: 0,
      pins: pins, pinsTotal: pins, health: 100,
      pushing: false, gameOver: false, paused: false,
      lastDamaged: 0, cylInterval: null,
    };

    LockWrap.classList.remove('lmg-hit', 'lmg-damage');
    lpSetPick(); lpSetCyl(); lpRenderPins();
    roundActive = true;
  }

  function lpPush() {
    if (!lock || lock.pushing || lock.gameOver || lock.paused || !roundActive) return;
    lock.pushing = true;
    if (lock.cylInterval) clearInterval(lock.cylInterval);

    var dist = clamp(Math.abs(lock.pinRot - lock.solveDeg) - lock.solvePadding, 0, LP_MAXDIST);
    // convertRanges(dist, 0, maxDist, 1, 0.02) * maxRot — ยิ่งใกล้ solve ยิ่งหมุนได้ไกล (1=สุด)
    var allowance = ((dist * (0.02 - 1)) / LP_MAXDIST + 1) * LP_MAXROT;

    lock.cylInterval = setInterval(function () {
      lock.cylRot += LP_CYL_SPEED;
      if (lock.cylRot >= LP_MAXROT) {
        lock.cylRot = LP_MAXROT; lpSetCyl();
        clearInterval(lock.cylInterval); lock.cylInterval = null;
        lpUnlock();
      } else if (lock.cylRot >= allowance) {
        lock.cylRot = allowance; lpSetCyl();
        lpDamage();
      } else {
        lpSetCyl();
      }
    }, 25);
  }

  function lpUnpush() {
    if (!lock) return;
    lock.pushing = false;
    if (lock.cylInterval) clearInterval(lock.cylInterval);
    lock.cylInterval = setInterval(function () {
      lock.cylRot -= LP_CYL_SPEED;
      if (lock.cylRot <= 0) { lock.cylRot = 0; clearInterval(lock.cylInterval); lock.cylInterval = null; }
      lpSetCyl();
    }, 25);
  }

  function lpDamage() {
    var now = performance.now();
    if (lock.lastDamaged && now - lock.lastDamaged <= LP_DMG_INTERVAL) return;
    lock.lastDamaged = now;
    lock.health -= lock.pinDamage;
    LockWrap.classList.remove('lmg-damage');
    void LockWrap.offsetWidth; // reflow → เล่นแอนิเมชันสั่นซ้ำได้
    LockWrap.classList.add('lmg-damage');
    if (lock.health <= 0) lpBreak();
  }

  function lpBreak() {
    lock.paused = true;
    if (lock.cylInterval) { clearInterval(lock.cylInterval); lock.cylInterval = null; }
    lock.pins--;
    lpRenderPins();
    // ท่อนบน/ล่างของเหล็กงัดกระเด็นแยกทางกัน (asset จริง pinTop/pinBott) ก่อนรีเซ็ตหรือจบเกม
    LockPinWrap.classList.add('lmg-broken');

    if (lock.pins > 0) {
      setTimeout(function () {
        if (!lock) return;
        lock.paused = false; lock.pushing = false;
        lock.cylRot = 0; lock.pinRot = 0; lock.health = 100;
        LockPinWrap.classList.remove('lmg-broken');
        lpSetPick(); lpSetCyl();
      }, 320);
    } else {
      lock.gameOver = true;
      setTimeout(function () { roundResult(false); }, 320);
    }
  }

  function lpUnlock() {
    lock.gameOver = true;
    LockWrap.classList.add('lmg-hit');
    setTimeout(function () { roundResult(true); }, 200);
  }

  // ── input ──────────────────────────────────────────────────────────────
  document.addEventListener('keydown', function (e) {
    if (!G || !roundActive) return;
    var code = e.keyCode;
    if (G.kind === 'spacebar') {
      if (code === 32) { e.preventDefault(); spacebarPress(); }
    } else if (G.kind === 'fishing') {
      if (code === 32) { e.preventDefault(); fishingPress(); }
    } else if (G.kind === 'circle') {
      var C = KEYCODE[code];
      if (C) { e.preventDefault(); circlePress(C); }
    } else if (G.kind === 'lockpick') {
      if (PUSH_KEYS[code]) { e.preventDefault(); lpPush(); }
    } else {
      var L = KEYCODE[code];
      if (L && L !== 'SPACE' && L !== 'E') { e.preventDefault(); sequencePress(L); }
    }
  });

  document.addEventListener('keyup', function (e) {
    if (!G || G.kind !== 'lockpick') return;
    if (PUSH_KEYS[e.keyCode]) { e.preventDefault(); lpUnpush(); }
  });

  document.addEventListener('mousemove', function (e) {
    if (!G || G.kind !== 'lockpick' || !lock || !roundActive || lock.gameOver || lock.paused) return;
    var dx = (typeof e.movementX === 'number') ? e.movementX : 0;
    lock.pinRot = clamp(lock.pinRot + dx / LP_MOUSE_SMOOTH, -LP_MAXROT, LP_MAXROT);
    lpSetPick();
  });

  window.addEventListener('message', function (ev) {
    var d = ev.data || {};
    if (d.action === 'lp_minigame:open') openGame(d.kind, d.cfg || {});
    else if (d.action === 'lp_minigame:close') closeGame();
  });

  // ── Mock for browser dev (no game backend) ────────────────────────────
  if (typeof GetParentResourceName !== 'function') {
    window.__lpMinigameMock = {
      openSpacebar: function (cfg) {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_minigame:open', kind: 'spacebar', cfg: cfg || { successNeeded: 3, failLimit: 1, duration: 2000, difficulty: 5 } } }));
      },
      openSequence: function (cfg) {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_minigame:open', kind: 'sequence', cfg: cfg || { successNeeded: 3, failLimit: 1, keys: 6, timePerSet: 3000, pool: ['W','A','S','D'] } } }));
      },
      openFishing: function (cfg) {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_minigame:open', kind: 'fishing', cfg: cfg || { successNeeded: 1, failLimit: 1, duration: 15000, speedMin: 1.5, speedMax: 2.5, zoneSize: 15 } } }));
      },
      openCircle: function (cfg) {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_minigame:open', kind: 'circle', cfg: cfg || { successNeeded: 3, failLimit: 1, difficulty: 5, duration: 4000, pool: ['E'] } } }));
      },
      openLockpick: function (cfg) {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_minigame:open', kind: 'lockpick', cfg: cfg || { successNeeded: 1, failLimit: 1, cursor: true, pins: 5, difficulty: 5 } } }));
      },
    };

    // ── Browser-only test trigger: index.html?test=lockpick[&pins=3&difficulty=8] ──
    // เปิดตรงเข้ามินิเกมเดียวทันทีตอนโหลดหน้า ไม่ต้องเปิด console เอง — ใช้เมาส์จริงของเบราว์เซอร์
    // เล็งได้แม่นกว่าการจำลอง event (movementX จริงมาจาก OS ไม่ใช่ synthetic dispatch)
    var qs = new URLSearchParams(location.search);
    var test = qs.get('test');
    if (test) {
      var openFn = { spacebar: 'openSpacebar', sequence: 'openSequence', fishing: 'openFishing', circle: 'openCircle', lockpick: 'openLockpick' }[test];
      if (openFn) {
        var cfg = {};
        qs.forEach(function (v, k) {
          if (k === 'test') return;
          var n = Number(v);
          cfg[k] = (v === 'true') ? true : (v === 'false') ? false : (!isNaN(n) && v !== '') ? n : v;
        });
        window.__lpMinigameMock[openFn](Object.keys(cfg).length ? cfg : undefined);
      }
    }
  }
})();
