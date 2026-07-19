(function () {
  var promptEl = document.getElementById('prompt');
  var keycapEl = document.getElementById('ltKeycap');
  var keyEl    = document.getElementById('ltKey');
  var fillEl   = document.getElementById('ltFill');
  var textEl   = document.getElementById('ltText');

  function esc(s) {
    return String(s || '')
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function extractKey(message) {
    var m = String(message).match(/\[([^\]]+)\]/);
    if (!m) return { key: null, text: String(message) };
    var key = m[1].trim();
    var text = (message.slice(0, m.index) + key + message.slice(m.index + m[0].length)).trim();
    return { key: key, text: text };
  }

  function highlightKey(text, key) {
    var safe = esc(text);
    if (!key) return safe;
    var k = esc(key).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    var re = new RegExp('\\b' + k + '\\b', 'i');
    return safe.replace(re, function (m) { return '<span class="lt-hl">' + m + '</span>'; });
  }

  // ความคืบหน้า = พื้นหลังป้ายไล่จากซ้าย (scaleX 0 -> 1) ตอนปกติว่างเปล่า
  function setFill(pct) {
    var v = Math.min(Math.max(pct, 0), 1);
    fillEl.style.transition = 'none';
    fillEl.style.transform = 'scaleX(' + v + ')';
  }

  // หยุดค้างตรงตำแหน่งปัจจุบัน — อ่านค่า computed (matrix) แล้วปักกลับไปเพื่อตัด transition ที่วิ่งอยู่
  function stopFill() {
    var frozen = getComputedStyle(fillEl).transform;
    fillEl.style.transition = 'none';
    fillEl.style.transform = (frozen && frozen !== 'none') ? frozen : 'scaleX(0)';
  }

  function startFill(duration) {
    fillEl.style.transition = 'none';
    fillEl.style.transform = 'scaleX(0)';
    fillEl.getBoundingClientRect(); // force reflow ให้ browser จำค่าเริ่มต้นก่อนค่อยเปลี่ยน transition
    fillEl.style.transition = 'transform ' + duration + 'ms linear';
    fillEl.style.transform = 'scaleX(1)';
  }

  function show(data) {
    var key = data.key ? String(data.key) : null;
    var text = data.message != null ? String(data.message) : '';

    if (!key) {
      var parsed = extractKey(text);
      key = parsed.key;
      text = parsed.text;
    }

    if (key) {
      keyEl.textContent = key;
      keycapEl.style.display = '';
    } else {
      keycapEl.style.display = 'none';
    }

    stopFill();
    setFill(0);

    textEl.innerHTML = highlightKey(text, key);
    promptEl.classList.toggle('lt-world', !!data.world);
    if (!data.world) {
      promptEl.style.left = '';
      promptEl.style.top = '';
      promptEl.style.visibility = '';
    }
    promptEl.classList.add('lt-show');
  }

  function hide() {
    promptEl.classList.remove('lt-show');
    promptEl.classList.remove('lt-world');
    promptEl.style.left = '';
    promptEl.style.top = '';
    promptEl.style.visibility = '';
    stopFill();
    setFill(0);
  }

  function setWorldPos(onScreen, x, y) {
    if (!onScreen) {
      promptEl.style.visibility = 'hidden';
      return;
    }
    promptEl.style.visibility = '';
    promptEl.style.left = (x * 100) + '%';
    promptEl.style.top = (y * 100) + '%';
  }

  window.addEventListener('message', function (event) {
    var d = event.data || {};
    switch (d.action) {
      case 'lp_textui:show':            show(d); break;
      case 'lp_textui:hide':            hide(); break;
      case 'lp_textui:progress':        if (Number(d.duration) > 0) startFill(Number(d.duration)); break;
      case 'lp_textui:progress_stop':   stopFill(); break;
      case 'lp_textui:progress_reset':  stopFill(); setFill(0); break;
      case 'lp_textui:holdProgress':    stopFill(); setFill((Number(d.pct) || 0) / 100); break;
      case 'lp_textui:mounted':         promptEl.classList.toggle('lt-mounted', !!d.mounted); break;
      case 'lp_textui:worldPos':        setWorldPos(d.onScreen, d.x, d.y); break;
    }
  });
})();
