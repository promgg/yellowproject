// NUI HELPERS

// ต้องไม่ redeclare GetParentResourceName — function declaration ถูก hoist ขึ้นก่อน IIFE
// ทำให้ window.GetParentResourceName ชี้ไปที่ฟังก์ชันของเราแทนที่จะเป็น native
var _resourceName = (typeof GetParentResourceName === 'function')
  ? GetParentResourceName()
  : 'AnimalFarm';

function nuiCallback(eventName, data) {
  data = data || {};
  fetch('https://' + _resourceName + '/' + eventName, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  }).catch(function(err) {
    console.error('[AnimalFarm] NUI callback "' + eventName + '" failed:', err);
  });
}

// MOCK DATA

var DEFAULT_DATA = {
  feedItems: [
    { icon: 'assets/item-162.png' },
    null, null, null,
  ],
  rewardItems: [
    { icon: 'assets/item-162.png' }, { icon: 'assets/item-167.png' },
    { icon: 'assets/item-168.png' }, { icon: 'assets/item-169.png' },
    { icon: 'assets/item-162.png' }, null,
    null, null,
  ],
  animals: [
    { id: 1, name: 'CAT', type: 'BABY', stage: '1/10', hp: 10,  exp: 50, state: 'loading' },
    { id: 2, name: 'CAT', type: 'BABY', stage: '5/10', hp: 80,  exp: 50, state: 'loading' },
    { id: 3, name: 'CAT', type: 'BABY', stage: '10/10', hp: 10, exp: 50, state: 'receive' },
    { id: 4, name: 'CAT', type: 'BABY', stage: '3/10', hp: 10, exp: 50, state: 'feed', timer: 600 },
  ]
};

// TIMERS
// client (Lua) เป็นเจ้าเดียวที่คำนวณ HP/timer แล้ว push มาทาง 'updateHp'
// ฝั่ง NUI แค่ render ตัวเลข ไม่มี setInterval countdown ของตัวเอง

function setCardTimer(id, sec) {
  var card = document.querySelector('.animal-card[data-id="' + id + '"]');
  var el = card && card.querySelector('.timer-time');
  if (!el) return;
  var s = Math.max(0, sec | 0);
  var mm = String(Math.floor(s / 60)).padStart(2, '0');
  var ss = String(s % 60).padStart(2, '0');
  el.textContent = mm + ':' + ss;
}

function clearAllTimers() { /* no-op: ไม่มี local timer แล้ว */ }

// item icons มาจาก vorp_inventory โดยตรง — nui://vorp_inventory/html/img/items/<name>.png
var ITEM_ICON_BASE = 'nui://vorp_inventory/html/img/items/';

function itemToSlot(item) {
  if (!item) return null;
  // รองรับทั้ง { icon } (mock) และ { name, qty } (server)
  if (item.icon) return item;
  if (item.name) return { icon: ITEM_ICON_BASE + item.name + '.png', label: item.name };
  return null;
}

// BUILDERS

function buildSlots(items, container) {
  container.innerHTML = '';
  items.forEach(function(rawItem) {
    var item = itemToSlot(rawItem);
    var slot = document.createElement('div');
    slot.className = 'item-slot';
    if (item && item.icon) {
      slot.classList.add('has-item');
      var img = document.createElement('img');
      img.src = item.icon;
      slot.appendChild(img);
    }
    container.appendChild(slot);
  });
}

function buildExpBar(pct) {
  var SEGS = 10;
  var litCount = Math.round((pct / 100) * SEGS);
  var html = '';
  for (var i = 0; i < SEGS; i++) {
    html += '<div class="exp-seg' + (i < litCount ? ' lit' : '') + '"></div>';
  }
  return html;
}

function buildActionArea(animal) {
  switch (animal.state) {
    case 'loading':
      return '<div class="spinner-wrap"><img src="assets/spinner.png" alt="loading"></div>';
    case 'receive':
      return '<div class="receive-icon"><img src="assets/package.png" alt="receive"></div>' +
             '<button class="btn-receive" onclick="onReceive(' + animal.id + ')">RECEIVE</button>';
    case 'feed': {
      var hungry = (animal.hp != null ? animal.hp : 100) <= 0;
      // เมื่อ hungry ให้แสดง deathTimer (เวลาก่อนตาย) แทน timer ปกติ
      var sec = hungry ? (animal.deathTimer || 0) : (animal.timer || 0);
      var m = String(Math.floor(sec / 60)).padStart(2, '0');
      var s = String(sec % 60).padStart(2, '0');
      return '<div class="timer-wrap">' +
               '<span class="timer-time' + (hungry ? ' timer-hungry' : '') + '">' + m + ':' + s + '</span>' +
               '<span class="timer-label' + (hungry ? ' timer-label-hungry' : '') + '">' + (hungry ? 'HUNGRY!' : 'Time out') + '</span>' +
             '</div>' +
             '<button class="btn-feed' + (hungry ? '' : ' btn-feed-disabled') + '"' +
               (hungry ? ' onclick="onFeed(' + animal.id + ')"' : ' disabled') +
             '>' + (hungry ? 'FEED' : 'NOT HUNGRY') + '</button>';
    }
    default:
      return '';
  }
}

function buildCard(animal) {
  var card = document.createElement('div');
  card.className = 'animal-card state-' + animal.state;
  card.dataset.id = animal.id;

  var animalImg = animal.image || 'assets/cat.png';

  card.innerHTML =
    '<div class="card-icon">' +
      '<div class="card-icon-inner">' +
        '<img src="' + animalImg + '" alt="' + animal.name + '">' +
      '</div>' +
    '</div>' +
    '<div class="card-info">' +
      '<div class="card-header-row">' +
        '<span class="card-name-cat">' + animal.name + '</span>' +
        '<span class="card-type">' + animal.type + '</span>' +
        '<span class="card-stage-label">STAGE:</span>' +
        '<span class="card-stage-bg">' +
          '<span class="card-stage-value">' + animal.stage + '</span>' +
        '</span>' +
      '</div>' +
      '<div class="card-bars">' +
        '<div class="bar-row">' +
          '<span class="bar-icon bar-icon-hp"><img src="assets/icon_hp.png" alt="HP"></span>' +
          '<div class="hp-bar-track">' +
            '<div class="hp-bar-fill" style="width:' + animal.hp + '%"></div>' +
          '</div>' +
          '<span class="bar-pct">' + animal.hp + '%</span>' +
        '</div>' +
        '<div class="bar-row">' +
          '<span class="bar-icon bar-icon-exp"><img src="assets/pet-bowl.png" alt="EXP"></span>' +
          '<div class="exp-bar-track">' + buildExpBar(animal.exp) + '</div>' +
          '<span class="bar-pct">' + animal.exp + '%</span>' +
        '</div>' +
      '</div>' +
    '</div>' +
    '<div class="card-action">' +
      buildActionArea(animal) +
    '</div>';

  return card;
}

// RENDER

function renderAnimalList(animals) {
  var list = document.getElementById('animal-list');
  list.innerHTML = '';
  animals.forEach(function(animal) {
    var card = buildCard(animal);
    list.appendChild(card);
    // ตัวเลข timer เริ่มต้น render จาก buildActionArea แล้ว — client tick จะ push อัปเดตต่อ
    if (animal.state === 'loading') {
      // fallback: refresh ถ้า loading ค้างเกิน 10 วิ
      (function(id) {
        setTimeout(function() {
          var el = document.querySelector('.animal-card[data-id="' + id + '"]');
          if (el && el.classList.contains('state-loading')) {
            nuiCallback('requestAnimals', {});
          }
        }, 10000);
      })(animal.id);
    }
  });
}

// ป้ายปุ่มซื้อ — อ้างราคาจาก Config.addPrice ที่ client ส่งมา ไม่ฮาร์ดโค้ดตัวเลข
// เปลี่ยนราคาใน config แล้วป้ายเปลี่ยนตาม ไม่ต้องแก้ที่นี่อีก
function setAddButtonLabel(price, moneyType) {
  var btn = document.getElementById('btn-add');
  if (!btn) return;

  // เช็ค null/undefined แยกต่างหาก: Number(null) ได้ 0 ซึ่งผ่านเงื่อนไขข้างล่างหมด
  // แล้วจะขึ้นป้ายว่า "(0$)" = บอกผู้เล่นว่าฟรี ทั้งที่แค่ไม่รู้ราคา
  var n = (price === null || price === undefined) ? NaN : Number(price);
  if (!isFinite(n) || n < 0) {          // ไม่รู้ราคา = ไม่ใส่วงเล็บ ดีกว่าโชว์เลขมั่ว
    btn.textContent = 'ซื้อสัตว์เลี้ยง';
    return;
  }

  var unit = Number(moneyType) === 1 ? ' ทอง' : '$';   // 0 = dollars, 1 = gold
  btn.textContent = 'ซื้อสัตว์เลี้ยง(' + n + unit + ')';
}

function renderUI(data) {
  setAddButtonLabel(data.addPrice, data.moneyType);
  if (data.feedItems) {
    buildSlots(data.feedItems, document.getElementById('feed-slots'));
  }
  if (data.rewardItems) {
    buildSlots(data.rewardItems.slice(0, 4), document.getElementById('reward-slots-1'));
    buildSlots(data.rewardItems.slice(4, 8), document.getElementById('reward-slots-2'));
  }
  renderAnimalList(data.animals || []);
}

function showHint(zoneName) {
  var label = document.getElementById('hint-label');
  if (label) label.textContent = 'เพื่อเปิด ' + (zoneName || 'Animal Farm');
  document.getElementById('zone-hint').classList.remove('hidden');
}

function hideHint() {
  document.getElementById('zone-hint').classList.add('hidden');
}

function showUI(data) {
  hideHint();
  clearAllTimers();
  renderUI(data || DEFAULT_DATA);
  document.getElementById('app').classList.remove('hidden');
}

function hideUI() {
  document.getElementById('app').classList.add('hidden');
  clearAllTimers();
}

// ACTIONS

var _btnLock = {};

function withLock(key, fn, ms) {
  if (_btnLock[key]) return;
  _btnLock[key] = true;
  fn();
  setTimeout(function() { delete _btnLock[key]; }, ms || 3000);
}

function onReceive(id) {
  withLock('receive_' + id, function() {
    nuiCallback('receiveReward', { animalId: id });
  });
}

function onFeed(id) {
  withLock('feed_' + id, function() {
    nuiCallback('feedAnimal', { animalId: id });
  });
}

function addAnimal() {
  withLock('addAnimal', function() {
    nuiCallback('addAnimal', {});
  });
}

document.getElementById('btn-add').addEventListener('click', addAnimal);

// NUI MESSAGES

window.addEventListener('message', function(event) {
  var payload = event.data || {};
  var action = payload.action;
  var data = payload.data;
  switch (action) {
    case 'openAnimalFarm':  showUI(data); break;
    case 'closeAnimalFarm': hideUI(); break;
    case 'showHint': showHint(data && data.zoneName); break;
    case 'hideHint': hideHint(); break;
    case 'updateAnimals':
      renderAnimalList(data.animals || []);
      break;

    case 'addCard': {
      var list = document.getElementById('animal-list');
      var newCard = buildCard(data);
      list.appendChild(newCard);
      break;
    }

    case 'updateCard': {
      var card = document.querySelector('.animal-card[data-id="' + data.id + '"]');
      if (!card) break;
      // update HP bar
      var hpFill = card.querySelector('.hp-bar-fill');
      if (hpFill) hpFill.style.width = data.hp + '%';
      var hpPct = card.querySelector('.bar-row:first-child .bar-pct');
      if (hpPct) hpPct.textContent = data.hp + '%';
      // update EXP bar
      var expTrack = card.querySelector('.exp-bar-track');
      if (expTrack) expTrack.innerHTML = buildExpBar(data.exp);
      var expPct = card.querySelector('.bar-row:last-child .bar-pct');
      if (expPct) expPct.textContent = data.exp + '%';
      // if state changed (e.g. feed → receive), update class + action area
      var stateChanged = data.state && card.className.indexOf('state-' + data.state) === -1;
      if (stateChanged) {
        card.className = 'animal-card state-' + data.state;
        var action2 = card.querySelector('.card-action');
        if (action2) action2.innerHTML = buildActionArea(Object.assign({}, data));
      }
      // feed แล้ว → rebuild action area (HP กลับ 100 → NOT HUNGRY, timer เต็ม)
      if (data.state === 'feed') {
        var actionEl = card.querySelector('.card-action');
        if (actionEl) actionEl.innerHTML = buildActionArea(Object.assign({}, data));
      }
      break;
    }

    case 'updateHp': {
      data.forEach(function(item) {
        var card = document.querySelector('.animal-card[data-id="' + item.id + '"]');
        if (!card) return;
        var hpFill = card.querySelector('.hp-bar-fill');
        if (hpFill) hpFill.style.width = item.hp + '%';
        var hpPct = card.querySelector('.bar-row:first-child .bar-pct');
        if (hpPct) hpPct.textContent = item.hp + '%';
        // render timer text จากค่าที่ client push มา (hungry → deathTimer, else → timer)
        if (card.className.indexOf('state-feed') !== -1) {
          var actionArea = card.querySelector('.card-action');
          var wasHungry = actionArea && actionArea.querySelector('.btn-feed-disabled') === null && actionArea.querySelector('.btn-feed') !== null;
          var nowHungry = item.hp <= 0;
          if (actionArea && wasHungry !== nowHungry) {
            // hungry state เปลี่ยน → rebuild ปุ่ม (NOT HUNGRY ↔ FEED)
            actionArea.innerHTML = buildActionArea({
              id: parseInt(card.dataset.id), state: 'feed', hp: item.hp,
              timer: item.timer || 0, deathTimer: item.deathTimer || 0,
            });
          } else {
            setCardTimer(item.id, nowHungry ? (item.deathTimer || 0) : (item.timer || 0));
          }
        }
      });
      break;
    }

    case 'removeCard': {
      var card = document.querySelector('.animal-card[data-id="' + data.id + '"]');
      if (card) card.remove();
      break;
    }


    case 'notify': {
      console.log('[AnimalFarm] ' + data.type + ': ' + data.message);
      break;
    }
  }
});

// CLOSE ON ESC

document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    nuiCallback('closeUI');
    hideUI();
  }
});

// UI เปิดเฉพาะเมื่อ client ส่ง openAnimalFarm เท่านั้น
