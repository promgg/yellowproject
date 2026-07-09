/* MJ-Planting NUI — app.js */
'use strict';

var _resourceName = (function() {
  try { return window.GetParentResourceName(); } catch(e) { return 'MJ-Planting'; }
})();

var root        = document.getElementById('root');
var plantPanels = document.getElementById('plant-panels');

var activePanels = {};

/* ── Per-plant panel ── */
var hintTexts = { water: 'to water plant', harvest: 'to harvest' };

function createPanel(p) {
  var anchor = document.createElement('div');
  anchor.className = 'pp-anchor';

  var dot  = document.createElement('div');  dot.className  = 'pp-dot';
  var line = document.createElement('div');  line.className = 'pp-line';
  var card = document.createElement('div');  card.className = 'pp-card';

  card.innerHTML =
    '<div class="pp-header">' +
      '<span class="pp-name"></span>' +
      '<span class="pp-id"></span>' +
    '</div>' +
    '<div class="pp-body">' +
      '<div class="pp-slots">' +
        '<div class="pp-slot seed-slot"><img src="" alt=""></div>' +
        '<div class="pp-slot feed-slot"><img src="" alt=""></div>' +
      '</div>' +
      '<div class="pp-vdiv"></div>' +
      '<div class="pp-progress">' +
        '<span class="pp-pct-label">Growth</span>' +
        '<span class="pp-pct-val">0%</span>' +
        '<div class="pp-bar-track"><div class="pp-bar-fill" style="width:0%"></div></div>' +
      '</div>' +
    '</div>' +
    '<div class="pp-hint hidden">' +
      '<div class="pp-key">E</div>' +
      '<span class="pp-hint-text"></span>' +
    '</div>';

  anchor.appendChild(dot);
  anchor.appendChild(line);
  anchor.appendChild(card);
  plantPanels.appendChild(anchor);
  return anchor;
}

function updatePanel(anchor, p) {
  var card = anchor.querySelector('.pp-card');
  card.querySelector('.pp-name').textContent = p.name || '';
  card.querySelector('.pp-id').textContent   = '#' + String(p.id).slice(-5);

  var seedImg = card.querySelector('.seed-slot img');
  var feedImg = card.querySelector('.feed-slot img');
  if (p.seedImg) seedImg.src = p.seedImg;
  if (p.feedImg) feedImg.src = p.feedImg;

  var pct = Math.min(Math.max(Math.round(p.pct || 0), 0), 100);
  card.querySelector('.pp-pct-val').textContent    = pct + '%';
  card.querySelector('.pp-bar-fill').style.width   = pct + '%';

  var hint = card.querySelector('.pp-hint');
  var txt  = hintTexts[p.state];
  if (txt) {
    hint.classList.remove('hidden');
    hint.querySelector('.pp-hint-text').textContent = txt;
  } else {
    hint.classList.add('hidden');
  }

  var scale = p.scale || 1;
  anchor.style.left      = p.x + 'px';
  anchor.style.top       = p.y + 'px';
  anchor.style.transform = 'translateY(-50%) scale(' + scale + ')';
  anchor.style.opacity   = (p.opacity !== undefined) ? p.opacity : 1;
}

function syncPanels(plants) {
  var seen = {};
  for (var i = 0; i < plants.length; i++) {
    var p  = plants[i];
    var id = String(p.id);
    seen[id] = true;
    if (!activePanels[id]) {
      activePanels[id] = createPanel(p);
    }
    updatePanel(activePanels[id], p);
  }
  var keys = Object.keys(activePanels);
  for (var k = 0; k < keys.length; k++) {
    if (!seen[keys[k]]) {
      activePanels[keys[k]].remove();
      delete activePanels[keys[k]];
    }
  }
}

/* ── NUI Messages ── */
window.addEventListener('message', function(ev) {
  var d = ev.data;
  if (!d || !d.action) return;

  switch (d.action) {
    case 'updatePlants':
      // root ถูกซ่อนด้วย 'hidden' ตั้งแต่ต้น ให้ updatePlants เป็นตัวจัดการเปิด/ปิดเอง
      // (ไม่มี enterZone/exitZone อีกแล้ว — reward preview ย้ายไป lp_rewardpanel หมดแล้ว)
      syncPanels(d.plants || []);
      if (d.plants && d.plants.length > 0) {
        root.classList.remove('hidden');
      } else {
        root.classList.add('hidden');
      }
      break;
  }
});

/* ── DEV mock ── */
(function() {
  if (typeof GetParentResourceName !== 'undefined') return;
  root.classList.remove('hidden');

  syncPanels([
    { id: '11111', x: 600, y: 400, scale: 1.0, name: 'Wheat', pct: 0,   state: 'growing',  seedImg: '', feedImg: '' },
    { id: '22222', x: 900, y: 500, scale: 0.85, name: 'Corn',  pct: 50,  state: 'water',    seedImg: '', feedImg: '' },
    { id: '33333', x: 750, y: 620, scale: 0.65, name: 'Carrot',pct: 100, state: 'harvest',  seedImg: '', feedImg: '' },
  ]);
})();
