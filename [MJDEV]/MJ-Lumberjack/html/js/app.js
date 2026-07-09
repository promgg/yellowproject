/* MJ-Lumberjack NUI — app.js */
'use strict';

var _resourceName = (function() {
  try { return window.GetParentResourceName(); } catch(e) { return 'MJ-Lumberjack'; }
})();

var root         = document.getElementById('root');
var actionBar    = document.getElementById('action-bar');
var dpSlots      = document.getElementById('dp-slots');
var pbFill       = document.getElementById('pb-fill');
var pbWrap       = document.getElementById('pb-wrap');
var hintIdle     = document.getElementById('hint-idle');
var hintChop     = document.getElementById('hint-chop');
var hintCancel   = document.getElementById('hint-cancel');
var durabilityEl = document.getElementById('durability-text');

var currentItems = [];

function setProgress(pct) {
  pbFill.style.width = Math.min(Math.max(pct, 0), 100) + '%';
}

function showIdle() {
  hintIdle.classList.remove('hidden');
  hintChop.classList.add('hidden');
  hintCancel.classList.add('hidden');
  pbWrap.classList.add('hidden');
  setProgress(0);
}

function showChopping(dur, maxDur) {
  hintIdle.classList.add('hidden');
  hintChop.classList.remove('hidden');
  hintCancel.classList.remove('hidden');
  pbWrap.classList.remove('hidden');
  durabilityEl.textContent = '| ขวาน: ' + dur + '/' + maxDur;
  setProgress(0);
}

function buildSlots(items) {
  dpSlots.innerHTML = '';
  for (var i = 0; i < items.length; i++) {
    var slot = document.createElement('div');
    slot.className = 'dp-slot has-item';
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
    dpSlots.appendChild(slot);
  }
}

window.addEventListener('message', function(ev) {
  var d = ev.data;
  if (!d || !d.action) return;

  switch (d.action) {

    case 'enterZone':
      if (d.items) { currentItems = d.items; buildSlots(d.items); }
      root.classList.remove('hidden');
      break;

    case 'exitZone':
      root.classList.add('hidden');
      actionBar.classList.add('hidden');
      setProgress(0);
      break;

    case 'showHint':
      actionBar.classList.remove('hidden');
      showIdle();
      break;

    case 'showChopping':
      actionBar.classList.remove('hidden');
      showChopping(d.durability, d.maxDur);
      break;

    case 'updateInfo':
      durabilityEl.textContent = '| ขวาน: ' + d.durability + '/' + d.maxDur;
      break;

    case 'setProgress':
      setProgress(d.pct || 0);
      break;

    case 'stopChopping':
      showIdle();
      break;
  }
});
