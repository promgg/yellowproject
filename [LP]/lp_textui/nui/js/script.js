(function () {
  var promptEl = document.getElementById('prompt');
  var badgeEl  = document.getElementById('ltBadge');
  var keyEl    = document.getElementById('ltKey');
  var ringEl   = document.getElementById('ltRingFill');
  var textEl   = document.getElementById('ltText');

  var CIRC = 2 * Math.PI * 18; // ~113.1

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

  function setRing(pct) {
    ringEl.style.transition = 'none';
    ringEl.style.strokeDashoffset = CIRC * (1 - Math.min(Math.max(pct, 0), 1));
  }

  function stopRing() {
    var frozen = getComputedStyle(ringEl).strokeDashoffset;
    ringEl.style.transition = 'none';
    ringEl.style.strokeDashoffset = frozen;
  }

  function startRing(duration) {
    ringEl.style.transition = 'none';
    ringEl.style.strokeDashoffset = CIRC;
    ringEl.getBoundingClientRect(); // force reflow ให้ browser จำค่าเริ่มต้นก่อนค่อยเปลี่ยน transition
    ringEl.style.transition = 'stroke-dashoffset ' + duration + 'ms linear';
    ringEl.style.strokeDashoffset = 0;
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
      badgeEl.style.display = '';
      stopRing();
      setRing(1);
    } else {
      badgeEl.style.display = 'none';
      stopRing();
    }

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
    stopRing();
    setRing(1);
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
      case 'lp_textui:progress':        if (Number(d.duration) > 0) startRing(Number(d.duration)); break;
      case 'lp_textui:progress_stop':   stopRing(); break;
      case 'lp_textui:progress_reset':  stopRing(); setRing(0); break;
      case 'lp_textui:holdProgress':    stopRing(); setRing((Number(d.pct) || 0) / 100); break;
      case 'lp_textui:mounted':         promptEl.classList.toggle('lt-mounted', !!d.mounted); break;
      case 'lp_textui:worldPos':        setWorldPos(d.onScreen, d.x, d.y); break;
    }
  });
})();
