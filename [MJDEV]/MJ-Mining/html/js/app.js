/* MJ-Mining NUI — app.js */
'use strict';

var _resourceName = (function() {
  try { return window.GetParentResourceName(); } catch(e) { return 'MJ-Mining'; }
})();

var root       = document.getElementById('root');
var actionBar  = document.getElementById('action-bar');
var dpSlots    = document.getElementById('dp-slots');
var pbFill     = document.getElementById('pb-fill');
var pbWrap     = document.getElementById('pb-wrap');
var hintIdle   = document.getElementById('hint-idle');
var hintMine   = document.getElementById('hint-mine');
var hintCancel = document.getElementById('hint-cancel');
var hintDur    = document.getElementById('hint-dur');
var hintSwing  = document.getElementById('hint-swing');

/* ── Build item slots in drop panel ── */
function buildSlots(items) {
  dpSlots.innerHTML = '';
  var total = 8;
  for (var i = 0; i < total; i++) {
    var slot = document.createElement('div');
    slot.className = 'dp-slot';
    if (items && items[i]) {
      slot.classList.add('has-item');
      var img = document.createElement('img');
      img.src = items[i].img || '';
      img.alt = '';
      img.onerror = function() { this.style.display = 'none'; };
      slot.appendChild(img);
      if (items[i].chance) {
        var lbl = document.createElement('span');
        lbl.className = 'dp-slot-label';
        lbl.textContent = items[i].chance + '%';
        slot.appendChild(lbl);
      }
    }
    dpSlots.appendChild(slot);
  }
}

/* ── Progress bar ── */
function setProgress(pct) {
  pbFill.style.width = Math.min(Math.max(pct, 0), 100) + '%';
}

/* ── NUI Messages ── */
window.addEventListener('message', function(ev) {
  var d = ev.data;
  if (!d || !d.action) return;

  switch (d.action) {
    case 'enterZone':
      if (d.items) buildSlots(d.items);
      root.classList.remove('hidden');
      break;

    case 'exitZone':
      root.classList.add('hidden');
      actionBar.classList.add('hidden');
      setProgress(0);
      break;

    case 'showHint':
      actionBar.classList.remove('hidden');
      hintIdle.classList.remove('hidden');
      hintMine.classList.add('hidden');
      hintCancel.classList.add('hidden');
      pbWrap.classList.add('hidden');
      setProgress(0);
      break;

    case 'showChopping':
      actionBar.classList.remove('hidden');
      hintIdle.classList.add('hidden');
      hintMine.classList.remove('hidden');
      hintCancel.classList.remove('hidden');
      pbWrap.classList.remove('hidden');
      if (hintDur)   hintDur.textContent   = (d.durability || 99) + '/' + (d.maxDur || 99);
      if (hintSwing) hintSwing.textContent = (d.swingCurrent || 0) + '/' + (d.swingTotal || 5);
      setProgress(0);
      break;

    case 'updateInfo':
      if (hintDur)   hintDur.textContent   = (d.durability || 0) + '/' + (d.maxDur || 99);
      if (hintSwing) hintSwing.textContent = (d.current || 0) + '/' + (d.total || 5);
      break;

    case 'setProgress':
      setProgress(d.pct || 0);
      break;

    case 'stopChopping':
      hintMine.classList.add('hidden');
      hintCancel.classList.add('hidden');
      pbWrap.classList.add('hidden');
      setProgress(0);
      break;
  }
});
