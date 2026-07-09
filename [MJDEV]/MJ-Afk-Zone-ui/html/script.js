/* ========================================================
   MJ-Afk-Zone-ui — AFK Panel Script
   Fixed 1920×1080 — key hint moved to lp_textui, notify moved to pNotify (ดู client.lua)
   ======================================================== */

const isNui = typeof GetParentResourceName === 'function';
const resourceName = isNui ? GetParentResourceName() : 'MJ-Afk-Zone-ui';

/* ---- DOM refs ---- */
const app          = document.getElementById('app');
const preview      = document.getElementById('preview-overlay');
const titleTh      = document.getElementById('afk-title-th');
const ringProgress = document.getElementById('afk-ring-progress');
const timer        = document.getElementById('afk-timer');
const zoneLabel    = document.getElementById('afk-zone-label');

/* ---- State ---- */
const RING_CIRCUMFERENCE = 366.9;

const state = {
  afkActive: false,
  zones: [],
  currentZone: null
};

/* ---- Helpers ---- */
function formatTimer(totalSeconds) {
  const s = Math.max(0, Math.floor(totalSeconds));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  return [h, m, sec].map(v => String(v).padStart(2, '0')).join(':');
}

function post(name, data) {
  if (!isNui) return Promise.resolve({ ok: true, mock: true });
  return fetch('https://' + resourceName + '/' + name, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {})
  }).catch(function() { return null; });
}

function setRingProgress(pct) {
  var clamped = Math.max(0, Math.min(100, pct));
  var offset = RING_CIRCUMFERENCE * (1 - clamped / 100);
  ringProgress.setAttribute('stroke-dashoffset', String(offset));
}

/* ---- NUI actions ---- */
function onUpdateProgressAll(zones, currentZoneName) {
  state.zones = zones || [];
  if (!state.afkActive || state.zones.length === 0) return;

  // เดิมเลือกโซนที่มี time สะสมสูงสุดมาโชว์ ทำให้เห็นเวลาโซนเก่าค้างไม่ขยับตอนเริ่ม AFK
  // ที่โซนใหม่ (โซนใหม่ time ยังน้อยกว่าโซนเก่าที่เคยสะสมไว้) — ต้องหาโซนที่ยืนอยู่จริงแทน
  var activeZone = null;
  for (var i = 0; i < state.zones.length; i++) {
    if (state.zones[i].name === currentZoneName) {
      activeZone = state.zones[i];
      break;
    }
  }
  if (!activeZone) return;
  state.currentZone = activeZone;

  var remaining = Math.max(0, (activeZone.required || 0) - (activeZone.time || 0));
  timer.textContent = formatTimer(remaining);
  var pct = activeZone.required > 0
    ? Math.min(100, (activeZone.time / activeZone.required) * 100) : 0;
  setRingProgress(pct);
}

function onStartAFKMode() {
  state.afkActive = true;
  zoneLabel.classList.add('hidden');
  app.classList.remove('hidden');
  setRingProgress(0);
  timer.textContent = '00:00:00';
}

function onHideAFK() {
  state.afkActive = false;
  state.currentZone = null;
  state.zones = [];
  app.classList.add('hidden');
  zoneLabel.classList.add('hidden');
  setRingProgress(0);
  timer.textContent = '00:00:00';
}

/* ---- Keyboard ---- */
document.addEventListener('keydown', function(e) {
  if (e.key === 'p' || e.key === 'P') {
    preview.style.display = (preview.style.display === 'none' || !preview.style.display) ? 'block' : 'none';
    return;
  }
  if (e.key === 'x' || e.key === 'X') {
    if (state.afkActive) { onHideAFK(); post('closeNUI'); }
  }
});

/* ---- Inbound NUI messages ---- */
window.addEventListener('message', function(event) {
  var data = event.data || {};
  switch (data.action) {
    case 'updateProgressAll':
      onUpdateProgressAll(data.zones, data.currentZone);
      if (!state.afkActive && data.zones && data.zones.length > 0 && data.currentZone) {
        // แสดง label ของโซนที่ยืนอยู่จริง (currentZone จาก client.lua) ไม่ใช่โซนที่ time สูงสุด
        var activeZ = null;
        for (var i = 0; i < data.zones.length; i++) {
          if (data.zones[i].name === data.currentZone) { activeZ = data.zones[i]; break; }
        }
        if (activeZ && activeZ.label) { zoneLabel.textContent = activeZ.label; zoneLabel.classList.remove('hidden'); }
      }
      break;
    case 'startAFKMode':   onStartAFKMode(); break;
    case 'hideAFK':        onHideAFK(); break;
  }
});

/* ---- Scale to fit viewport ---- */
function updateScale() {
  var s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080, 1);
  document.documentElement.style.setProperty('--s', s.toFixed(4));
}
window.addEventListener('resize', updateScale);
updateScale();

/* ---- Mock mode ---- */
if (!isNui) {
  document.addEventListener('DOMContentLoaded', function() {
    console.log('[afk-ui] Mock mode');
    updateScale();
    state.afkActive = true;
    app.classList.remove('hidden');
    timer.textContent = '00:04:42';
    setRingProgress(47);
  });
}
