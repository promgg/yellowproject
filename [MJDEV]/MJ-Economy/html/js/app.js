/* MJ-Economy NUI — app.js */
'use strict';

var E = {
  app:          document.getElementById('app'),
  backdrop:     document.getElementById('modal-backdrop'),
  grid:         document.getElementById('item-grid'),
  ecoList:      document.getElementById('eco-list'),
  sellAllTotal: document.getElementById('sell-all-total'),
  panelSellAll: document.getElementById('panel-sell-all'),
  psaItems:     document.getElementById('psa-items'),
  psaTotal:     document.getElementById('psa-total'),
  panelSell:    document.getElementById('panel-sell'),
  psImg:        document.getElementById('ps-item-img'),
  psName:       document.getElementById('ps-item-name'),
  psPrice:      document.getElementById('ps-item-price'),
  qtyInput:     document.getElementById('qty-input'),
  psTotal:      document.getElementById('ps-total'),
  btnSellAll:   document.getElementById('btn-sell-all'),
  btnConfirmAll:document.getElementById('btn-confirm-all'),
  btnConfirm:   document.getElementById('btn-confirm'),
  btnMin:       document.getElementById('btn-min'),
  btnMax:       document.getElementById('btn-max'),
};

var state = {
  items: [],
  ecoData: [],
  selectedItem: null,
  open: false,
};

function fmt(n) {
  return Number(n).toLocaleString('en-US') + ' $';
}
function clamp(v, mn, mx) {
  return Math.max(mn, Math.min(mx, v));
}

function setScale() {
  var s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
  document.documentElement.style.setProperty('--s', s);
}
window.addEventListener('resize', setScale);
setScale();

function showModal(panel) {
  E.backdrop.classList.add('show');
  panel.style.display = 'block';
}
function hideModals() {
  E.backdrop.classList.remove('show');
  E.panelSell.style.display = 'none';
  E.panelSellAll.style.display = 'none';
}

function closeUI() {
  hideModals();
  E.app.classList.remove('active');
  state.open = false;
  state.selectedItem = null;
  navigator.sendBeacon('https://MJ-Economy/closeUI', JSON.stringify({}));
}

function buildGrid() {
  E.grid.innerHTML = '';
  var total = 0;
  state.items.forEach(function(item) {
    if (!item.canSell) return;
    total += item.price * item.count;
    var card = document.createElement('div');
    card.className = 'item-card' + (item.count === 0 ? ' no-stock' : '');
    card.innerHTML =
      '<div class="item-card-icon"><svg width="6" height="6" viewBox="0 0 6 6" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M0 0H5.71429V1.26984H0V0ZM0.31746 1.5873H5.39683V5.71429H0.31746V1.5873ZM2.06349 2.53968C2.02139 2.53968 1.98102 2.55641 1.95125 2.58617C1.92149 2.61594 1.90476 2.65631 1.90476 2.69841V3.1746H3.80952V2.69841C3.80952 2.65631 3.7928 2.61594 3.76303 2.58617C3.73327 2.55641 3.69289 2.53968 3.65079 2.53968H2.06349Z" fill="white"/></svg></div>' +
      '<div class="item-card-count">' + item.count + '</div>' +
      '<img src="' + item.img + '" alt="" onerror="this.src=\'img/error.png\'">' +
      '<p class="item-card-price">' + fmt(item.price) + '</p>' +
      '<p class="item-card-name">' + item.label + '</p>';
    card.addEventListener('click', function() {
      if (item.count === 0) return;
      selectItem(item, card);
    });
    E.grid.appendChild(card);
  });
  E.sellAllTotal.textContent = fmt(total);
}

function buildEco() {
  E.ecoList.innerHTML = '';
  state.ecoData.forEach(function(row) {
    var div = document.createElement('div');
    div.className = 'eco-row';
    var trendClass = row.trend > 0 ? 'up' : row.trend < 0 ? 'down' : 'neutral';
    var arrow = row.trend > 0 ? '▲' : row.trend < 0 ? '▼' : '—';
    div.innerHTML =
      '<img class="eco-row-img" src="' + row.img + '" alt="" onerror="this.src=\'img/error.png\'">' +
      '<p class="eco-row-name">' + row.label + '</p>' +
      '<div class="eco-row-badge ' + trendClass + '">' + arrow + ' ' + Math.abs(row.trend) + '%</div>';
    E.ecoList.appendChild(div);
  });
}

function selectItem(item, cardEl) {
  state.selectedItem = item;
  document.querySelectorAll('.item-card.active').forEach(function(c) {
    c.classList.remove('active');
  });
  if (cardEl) cardEl.classList.add('active');
  E.psImg.src = item.img;
  E.psImg.onerror = function() { this.src = 'img/error.png'; };
  E.psName.textContent = item.label;
  E.psPrice.textContent = fmt(item.price);
  E.qtyInput.value = 1;
  E.qtyInput.max = item.count;
  updateSellTotal();
  hideModals();
  showModal(E.panelSell);
}

function updateSellTotal() {
  var item = state.selectedItem;
  if (!item) return;
  var qty = parseInt(E.qtyInput.value) || 1;
  qty = clamp(qty, 1, item.count);
  E.qtyInput.value = qty;
  E.psTotal.textContent = fmt(item.price * qty);
}

function buildSellAllPanel() {
  E.psaItems.innerHTML = '';
  var total = 0;
  state.items.forEach(function(item) {
    if (!item.canSell || item.count === 0) return;
    var sub = item.price * item.count;
    total += sub;
    var row = document.createElement('div');
    row.className = 'psa-row';
    row.innerHTML = '<span>' + item.label + ' x' + item.count + '</span><span>' + fmt(sub) + '</span>';
    E.psaItems.appendChild(row);
  });
  E.psaTotal.textContent = fmt(total);
}

window.addEventListener('message', function(ev) {
  var data = ev.data;
  if (!data || !data.action) return;
  if (data.action === 'openUI') {
    state.items   = data.items   || [];
    state.ecoData = data.ecoData || [];
    buildGrid();
    buildEco();
    E.panelSell.style.display = 'none';
    E.panelSellAll.style.display = 'none';
    state.open = true;
    E.app.classList.add('active');
  } else if (data.action === 'closeUI') {
    closeUI();
  }
});

E.btnMin.addEventListener('click', function() {
  E.qtyInput.value = 1;
  updateSellTotal();
});
E.btnMax.addEventListener('click', function() {
  if (state.selectedItem) {
    E.qtyInput.value = state.selectedItem.count;
    updateSellTotal();
  }
});
E.qtyInput.addEventListener('input', updateSellTotal);

E.btnSellAll.addEventListener('click', function() {
  buildSellAllPanel();
  hideModals();
  showModal(E.panelSellAll);
});
E.btnConfirmAll.addEventListener('click', function() {
  navigator.sendBeacon('https://MJ-Economy/sellAll', JSON.stringify({}));
  closeUI();
});
E.btnConfirm.addEventListener('click', function() {
  var item = state.selectedItem;
  if (!item) return;
  var qty = clamp(parseInt(E.qtyInput.value) || 1, 1, item.count);
  navigator.sendBeacon('https://MJ-Economy/sellItem', JSON.stringify({ name: item.name, count: qty }));
  E.panelSell.style.display = 'none';
  closeUI();
});

document.addEventListener('keydown', function(ev) {
  if (ev.key === 'Escape' && state.open) {
    if (E.backdrop.classList.contains('show')) hideModals();
    else closeUI();
  }
});

E.backdrop.addEventListener('click', hideModals);
