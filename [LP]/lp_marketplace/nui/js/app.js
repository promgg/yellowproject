// app.js — Marketplace UI logic

const ITEM_IMG_BASE = 'nui://vorp_inventory/html/img/items';

function itemImg(name, cls) {
    const c = cls || 'row-item-img';
    return `<img class="${c}" src="${ITEM_IMG_BASE}/${name}.png" onerror="this.style.display='none';this.nextElementSibling.style.display=''"><i class="fa-solid fa-box" style="display:none;font-size:12px"></i>`;
}

const state = {
    tab:        'buy',
    category:   'all',
    search:     '',
    page:       1,
    totalPages: 1,
    // Sell form
    selectedItem:     null,
    selectedQty:      1,
    selectedDuration: 0,   // index ใน Config.DurationOptions
    selectedCurrency: 'money',
    // Pending buy
    pendingBuyId:     null,
    pendingBuyQty:    1,
    pendingBuyMax:    1,
    pendingBuyPrice:  0,
    pendingBuyCurrency: 'money',
    // Config (received from Lua)
    categories:   [],
    currencies:   {},
    durations:    [],
    taxRate:      10,
    taxMin:       100,
    itemsPerPage: 20,
    // Cached data for safe data-attribute pattern
    _listings:   [],
    _myListings: [],
    _claims:     [],
    _invItems:   null,
    _invSelected: null,
};

let searchTimer = null;

// ─── Open / Close ─────────────────────────────────────────────────────────────
function onOpen(msg) {
    if (msg.theme) applyTheme(msg.theme);

    state.categories   = msg.categories   || [];
    state.currencies   = msg.currencies   || {};
    state.durations    = msg.durations    || [12, 24, 48];
    state.taxRate      = msg.taxRate      || 10;
    state.taxMin       = msg.taxMin       != null ? msg.taxMin : 100;
    state.itemsPerPage = msg.itemsPerPage || 20;

    buildCategoryList();
    buildDurationRadios();
    buildCurrencyRadios();

    showUI();
    switchTab('buy');
}

function showUI() {
    document.getElementById('marketWrap').classList.remove('hidden');
}

function hideUI() {
    document.getElementById('marketWrap').classList.add('hidden');
}

function applyTheme(t) {
    const r = document.documentElement.style;
    if (t.accentBuy)    r.setProperty('--accent-buy',    t.accentBuy);
    if (t.accentSell)   r.setProperty('--accent-sell',   t.accentSell);
    if (t.accentItem)   r.setProperty('--accent-item',   t.accentItem);
    if (t.btnBuyBg)     r.setProperty('--btn-buy-bg',    t.btnBuyBg);
    if (t.btnSellBg)    r.setProperty('--btn-sell-bg',   t.btnSellBg);
    if (t.btnItemBg)    r.setProperty('--btn-item-bg',   t.btnItemBg);
    if (t.accent)       r.setProperty('--accent',        t.accent);
    if (t.accentDeep)   r.setProperty('--accent-deep',   t.accentDeep);
    if (t.bgPrimary)    r.setProperty('--bg-primary',    t.bgPrimary);
    if (t.bgSecondary)  r.setProperty('--bg-secondary',  t.bgSecondary);
    if (t.bgTertiary)   r.setProperty('--bg-tertiary',   t.bgTertiary);
    if (t.bgHover)      r.setProperty('--bg-hover',      t.bgHover);
    if (t.border)       r.setProperty('--border',        t.border);
    if (t.textPrimary)  r.setProperty('--text-primary',  t.textPrimary);
    if (t.textSecondary)r.setProperty('--text-secondary',t.textSecondary);
    if (t.textMuted)    r.setProperty('--text-muted',    t.textMuted);
    if (t.radius)       r.setProperty('--radius',        t.radius);
    if (t.radiusSm)     r.setProperty('--radius-sm',     t.radiusSm);
}

// ─── Build sidebar elements ───────────────────────────────────────────────────
function buildCategoryList() {
    const el = document.getElementById('catList');
    el.innerHTML = '';

    const allBtn = createCatBtn('all', 'ทั้งหมด', 'fa-layer-group', state.category === 'all');
    el.appendChild(allBtn);

    for (const cat of state.categories) {
        el.appendChild(createCatBtn(cat.id, cat.label, cat.icon, state.category === cat.id));
    }
}

function createCatBtn(id, label, icon, active) {
    const btn = document.createElement('button');
    btn.className = 'cat-btn' + (active ? ' active' : '');
    btn.innerHTML = `<i class="fa-solid ${icon}"></i><span>${label}</span>`;
    btn.onclick = () => {
        state.category = id;
        state.page     = 1;
        document.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        NUI.getListings({ category: id, search: state.search, page: 1 });
    };
    return btn;
}

function buildDurationRadios() {
    const el = document.getElementById('durationRadios');
    el.innerHTML = '';
    state.durations.forEach((h, i) => {
        const label = document.createElement('label');
        label.className = 'sf-radio' + (i === 0 ? ' selected' : '');
        label.innerHTML = `<input type="radio" name="duration" value="${i}"><i class="fa-solid fa-clock"></i> ${h} ชั่วโมง`;
        label.onclick = () => {
            document.querySelectorAll('.sf-radio[data-type="dur"]').forEach(l => l.classList.remove('selected'));
            label.classList.add('selected');
            state.selectedDuration = i;
        };
        label.dataset.type = 'dur';
        el.appendChild(label);
    });
    state.selectedDuration = 0;
}

function buildCurrencyRadios() {
    const el = document.getElementById('currencyRadios');
    el.innerHTML = '';
    let first = true;
    for (const [key, cfg] of Object.entries(state.currencies)) {
        if (!cfg.enabled) continue;
        const label = document.createElement('label');
        label.className = 'sf-radio' + (first ? ' selected' : '');
        label.style.setProperty('--cur-color', cfg.color || '#e0e0e0');
        label.innerHTML = `<input type="radio" name="currency" value="${key}"><i class="fa-solid fa-coins" style="color:${cfg.color}"></i> ${cfg.label}`;
        label.onclick = () => {
            document.querySelectorAll('.sf-radio[data-type="cur"]').forEach(l => l.classList.remove('selected'));
            label.classList.add('selected');
            state.selectedCurrency = key;
            updateTaxDisplay();
        };
        label.dataset.type = 'cur';
        el.appendChild(label);
        if (first) { state.selectedCurrency = key; first = false; }
    }
}

// ─── Tab switching ────────────────────────────────────────────────────────────
function switchTab(tab) {
    state.tab = tab;

    ['buy','sell','item'].forEach(t => {
        document.getElementById('tab' + cap(t)).classList.toggle('active', t === tab);
    });
    ['paneBuy','paneSell','paneItem'].forEach(id => {
        document.getElementById(id).classList.remove('active');
    });
    document.getElementById('pane' + cap(tab)).classList.add('active');
    ['sbBuy','sbSell','sbItem'].forEach(id => {
        document.getElementById(id).style.display = 'none';
    });
    document.getElementById('sb' + cap(tab)).style.display = '';

    document.querySelector('.search-wrap').style.visibility = tab === 'buy' ? 'visible' : 'hidden';

    if (tab === 'buy')  { state.page = 1; NUI.getListings({ category: state.category, search: state.search, page: 1 }); }
    if (tab === 'sell') NUI.getMyListings();
    if (tab === 'item') NUI.getItemClaims();
}

function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1); }

// ─── Search ───────────────────────────────────────────────────────────────────
function onSearch(val) {
    state.search = val;
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
        state.page = 1;
        NUI.getListings({ category: state.category, search: val, page: 1 });
    }, 350);
}

// ─── BUY Tab rendering ────────────────────────────────────────────────────────
function onReceiveListings(data) {
    const rows  = data.listings || [];
    const total = data.total    || 0;
    state.page       = data.page         || 1;
    state.totalPages = Math.max(1, Math.ceil(total / state.itemsPerPage));

    // เก็บ listings ใน state สำหรับ data-attribute pattern (ป้องกัน JS injection)
    state._listings = rows;

    const el = document.getElementById('buyRows');
    if (!rows.length) {
        el.innerHTML = '<div class="tbl-empty"><i class="fa-solid fa-box-open"></i><br>ไม่มีสินค้า</div>';
        document.getElementById('buyPagination').innerHTML = '';
        return;
    }

    el.innerHTML = rows.map((r, i) => `
    <div class="tbl-row" data-idx="${i}" style="grid-template-columns:40px 1fr 120px 160px 80px">
      <div class="row-icon">${itemImg(r.item_name)}</div>
      <div>
        <div class="row-name">${esc(r.item_label)}</div>
        <div class="row-seller">โดย ${esc(r.seller_name)}</div>
      </div>
      <div class="row-cat">${getCatLabel(r.category)}</div>
      <div class="row-exp ${isExpiringSoon(r.expires_at) ? 'soon' : ''}">${formatDate(r.expires_at)}</div>
      <div class="row-price ${r.currency}">${fmt(r.price)}</div>
    </div>`).join('');

    // attach event listeners แทน inline onclick — ป้องกัน single quote injection
    el.querySelectorAll('.tbl-row[data-idx]').forEach(row => {
        row.addEventListener('click', () => {
            const r = state._listings[parseInt(row.dataset.idx, 10)];
            if (r) openBuyConfirm(r.id, r.item_label, r.seller_name, r.price, r.currency, r.quantity);
        });
    });

    buildPagination('buyPagination', state.page, state.totalPages, (p) => {
        state.page = p;
        NUI.getListings({ category: state.category, search: state.search, page: p });
    });
}

// ─── SELL Tab rendering ───────────────────────────────────────────────────────
function onReceiveMyListings(listings) {
    state._myListings = listings;

    const el = document.getElementById('sellRows');
    if (!listings.length) {
        el.innerHTML = '<div class="tbl-empty"><i class="fa-solid fa-box-open"></i><br>ไม่มีสินค้าที่กำลังขาย</div>';
        return;
    }
    el.innerHTML = listings.map((r, i) => `
    <div class="tbl-row" style="grid-template-columns:40px 1fr 120px 160px 90px 90px">
      <div class="row-icon">${itemImg(r.item_name)}</div>
      <div>
        <div class="row-name">${esc(r.item_label)}</div>
        <div class="row-seller">x${r.quantity}</div>
      </div>
      <div class="row-cat">${getCatLabel(r.category)}</div>
      <div class="row-exp ${isExpiringSoon(r.expires_at) ? 'soon' : ''}">${formatDate(r.expires_at)}</div>
      <div class="row-price ${r.currency}">${fmt(r.price)}</div>
      <div class="row-action-cell"><button class="row-action cancel" data-id="${r.id}" data-label="${esc(r.item_label)}" data-qty="${r.quantity}" onclick="cancelListing(this)">ยกเลิก</button></div>
    </div>`).join('');
}

// ─── ITEM Tab rendering ───────────────────────────────────────────────────────
function onReceiveItemClaims(claims) {
    state._claims = claims;

    const el = document.getElementById('itemRows');
    if (!claims.length) {
        el.innerHTML = '<div class="tbl-empty"><i class="fa-solid fa-box-open"></i><br>ไม่มีรายการที่รับได้</div>';
        return;
    }
    el.innerHTML = claims.map((r, i) => {
        const statusLabel = r.status === 'sold' ? 'การขายสำเร็จ' : 'หมดอายุ';
        const btnLabel    = r.status === 'sold' ? 'กดเพื่อรับเงิน' : 'รับของคืน';
        return `
    <div class="tbl-row" style="grid-template-columns:40px 1fr 120px 130px 110px">
      <div class="row-icon">${itemImg(r.item_name)}</div>
      <div>
        <div class="row-name">${esc(r.item_label)}</div>
        <div class="row-seller">x${r.quantity}</div>
      </div>
      <div class="row-cat">${getCatLabel(r.category)}</div>
      <div><span class="status-badge ${r.status}">${statusLabel}</span></div>
      <div class="row-action-cell"><button class="row-action claim" data-idx="${i}" onclick="claimItem(this)">${btnLabel}</button></div>
    </div>`;
    }).join('');
}

// ─── Inventory Popup ──────────────────────────────────────────────────────────
function openInventory() {
    document.getElementById('qtyValue').value = '1';
    state.selectedQty  = 1;
    state._invSelected = null;
    document.getElementById('invGrid').innerHTML = '<div style="padding:20px;color:var(--text-muted);font-size:13px;text-align:center">กำลังโหลด...</div>';
    document.getElementById('inventoryOverlay').style.display = 'flex';
    NUI.getInventory();
}

function closeInventory() {
    document.getElementById('inventoryOverlay').style.display = 'none';
    state._invItems    = null;
    state._invSelected = null;
}

function onReceiveInventory(inventory) {
    state._invItems = inventory;
    state._invSelected = null;

    const grid = document.getElementById('invGrid');
    if (!inventory.length) {
        grid.innerHTML = '<div style="padding:20px;color:var(--text-muted);font-size:13px;text-align:center;grid-column:1/-1">ไม่มีไอเทมในคลัง</div>';
        return;
    }

    grid.innerHTML = inventory.map((item, i) => `
    <div class="inv-item" id="inv-${i}" onclick="selectInvItem(${i})">
      <div class="inv-item-icon">${itemImg(item.name, 'inv-item-img')}</div>
      <div class="inv-item-label" title="${esc(item.label)}">${esc(item.label)}</div>
      <div class="inv-item-count">x${item.count}</div>
    </div>`).join('');
}

function selectInvItem(i) {
    document.querySelectorAll('.inv-item').forEach(el => el.classList.remove('selected'));
    document.getElementById('inv-' + i).classList.add('selected');
    state._invSelected = i;
    state.selectedQty  = 1;
    const inp = document.getElementById('qtyValue');
    inp.value = '1';
    inp.max   = state._invItems[i].count;
}

function stepQty(delta) {
    const inp = document.getElementById('qtyValue');
    inp.value = parseInt(inp.value || 1) + delta;
    onQtyInput(inp);
}

function onQtyInput(inp) {
    if (state._invSelected === null) { inp.value = 1; return; }
    const max = state._invItems[state._invSelected].count;
    let v = parseInt(inp.value) || 1;
    if (v < 1)   v = 1;
    if (v > max) v = max;
    inp.value = v;
    state.selectedQty = v;
}

function confirmInventorySelect() {
    if (state._invSelected === null) { showToast('กรุณาเลือกไอเทม'); return; }
    const item = state._invItems[state._invSelected];
    state.selectedItem = item;
    state.selectedQty  = parseInt(document.getElementById('qtyValue').value) || 1;

    document.getElementById('itemThumb').innerHTML = itemImg(item.name, 'thumb-img');
    document.getElementById('sellItemName').textContent = item.label;
    document.getElementById('sellItemType').textContent = getCatLabel(item.category || 'general');
    document.getElementById('sellItemQty').textContent  = 'จำนวน: ' + state.selectedQty;

    updateTaxDisplay();
    closeInventory();
}

// ─── Sell Form ────────────────────────────────────────────────────────────────
function updateTaxDisplay() {
    const price = parseInt(document.getElementById('priceInput').value) || 0;
    const tax   = Math.max(state.taxRate > 0 ? state.taxMin : 0, Math.floor(price * state.taxRate / 100));
    const net   = price - tax;
    const el    = document.getElementById('taxDisplay');
    if (price <= 0) { el.innerHTML = '—'; return; }
    el.innerHTML = `ภาษี <span>${fmt(tax)}</span> · ได้รับ <span style="color:var(--accent-buy)">${fmt(net)}</span>`;
}

function clearSellForm() {
    state.selectedItem = null;
    state.selectedQty  = 1;
    document.getElementById('itemThumb').innerHTML = '<i class="fa-solid fa-plus"></i>';
    document.getElementById('sellItemName').textContent = 'เลือกสินค้า';
    document.getElementById('sellItemType').textContent = 'ประเภทสินค้า';
    document.getElementById('sellItemQty').textContent  = 'จำนวน: —';
    document.getElementById('priceInput').value = '';
    document.getElementById('taxDisplay').innerHTML = '—';
}

function submitListing() {
    if (!state.selectedItem) { showToast('กรุณาเลือกไอเทมก่อน'); return; }
    const price = parseInt(document.getElementById('priceInput').value);
    if (!price || price <= 0) { showToast('กรุณากรอกราคา'); return; }

    NUI.listItem({
        itemName:      state.selectedItem.name,
        quantity:      state.selectedQty,
        price:         price,
        currency:      state.selectedCurrency,
        durationIndex: state.selectedDuration + 1,
    });
    clearSellForm();
}

// ─── Buy Confirm ──────────────────────────────────────────────────────────────
function openBuyConfirm(id, label, seller, price, currency, qty) {
    state.pendingBuyId       = id;
    state.pendingBuyMax      = qty;
    state.pendingBuyPrice    = price;
    state.pendingBuyCurrency = currency;
    state.pendingBuyQty      = 1;

    const curLabel = (state.currencies[currency] && state.currencies[currency].label) || currency;
    const curColor = (state.currencies[currency] && state.currencies[currency].color) || '#e0e0e0';
    document.getElementById('buyConfirmBody').innerHTML =
        `<strong>${esc(label)}</strong> (มีทั้งหมด ${qty} ชิ้น)<br>จาก: ${esc(seller)}<br>` +
        `ราคาต่อชิ้น: <strong style="color:${curColor}">${fmt(price)} ${curLabel}</strong>`;
    const buyInp = document.getElementById('buyQtyValue');
    buyInp.value = '1';
    buyInp.max   = qty;
    document.getElementById('buyTotalPrice').textContent = fmt(price) + ' ' + curLabel;
    document.getElementById('buyTotalPrice').style.color = curColor;
    document.getElementById('buyOverlay').style.display = 'flex';
}

function stepBuyQty(delta) {
    const inp = document.getElementById('buyQtyValue');
    inp.value = parseInt(inp.value || 1) + delta;
    onBuyQtyInput(inp);
}

function onBuyQtyInput(inp) {
    let v = parseInt(inp.value) || 1;
    if (v < 1)                    v = 1;
    if (v > state.pendingBuyMax)  v = state.pendingBuyMax;
    inp.value = v;
    state.pendingBuyQty = v;

    const currency = state.pendingBuyCurrency;
    const curLabel = (state.currencies[currency] && state.currencies[currency].label) || currency;
    const curColor = (state.currencies[currency] && state.currencies[currency].color) || '#e0e0e0';
    document.getElementById('buyTotalPrice').textContent = fmt(state.pendingBuyPrice * v) + ' ' + curLabel;
    document.getElementById('buyTotalPrice').style.color = curColor;
}

function closeBuyConfirm() {
    document.getElementById('buyOverlay').style.display = 'none';
    state.pendingBuyId  = null;
    state.pendingBuyQty = 1;
}

function confirmBuy() {
    if (!state.pendingBuyId) return;
    const qty = parseInt(document.getElementById('buyQtyValue').value) || 1;
    NUI.buyItem(state.pendingBuyId, Math.min(qty, state.pendingBuyMax));
    closeBuyConfirm();
}

// ─── Cancel / Claim ───────────────────────────────────────────────────────────
let _pendingCancelId = null;

function cancelListing(btn) {
    const id    = parseInt(btn.dataset.id, 10);
    const label = btn.dataset.label || '';
    const qty   = btn.dataset.qty   || '1';
    if (!id) return;
    _pendingCancelId = id;
    document.getElementById('cancelConfirmBody').innerHTML =
        `ต้องการยกเลิกการขาย <strong>${esc(label)}</strong> x${qty}?<br>` +
        `<span style="color:var(--text-muted);font-size:13px">ของจะถูกคืนกลับมาในคลัง</span>`;
    document.getElementById('cancelOverlay').style.display = 'flex';
}

function closeCancelConfirm() {
    document.getElementById('cancelOverlay').style.display = 'none';
    _pendingCancelId = null;
}

function confirmCancel() {
    if (!_pendingCancelId) return;
    NUI.cancelListing(_pendingCancelId);
    closeCancelConfirm();
}

function claimItem(btn) {
    const idx   = parseInt(btn.dataset.idx, 10);
    const claim = state._claims[idx];
    if (!claim) return;
    NUI.claimItem(claim.id);
}

// ─── Pagination ───────────────────────────────────────────────────────────────
function buildPagination(elId, current, total, cb) {
    const el = document.getElementById(elId);
    if (total <= 1) { el.innerHTML = ''; return; }
    let html = '';
    if (current > 1) html += `<button class="page-btn" onclick="(${cb.toString()})(${current-1})">‹</button>`;
    for (let p = Math.max(1, current-2); p <= Math.min(total, current+2); p++) {
        html += `<button class="page-btn ${p===current?'active':''}" onclick="(${cb.toString()})(${p})">${p}</button>`;
    }
    if (current < total) html += `<button class="page-btn" onclick="(${cb.toString()})(${current+1})">›</button>`;
    el.innerHTML = html;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function esc(s) {
    return String(s || '')
        .replace(/&/g,'&amp;').replace(/</g,'&lt;')
        .replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
}

function fmt(n) {
    return Number(n).toLocaleString('th-TH');
}

function getCatLabel(id) {
    if (id === 'all') return 'ทั้งหมด';
    const found = state.categories.find(c => c.id === id);
    return found ? found.label : id;
}

function formatDate(dtStr) {
    if (!dtStr) return '—';
    let d;
    if (typeof dtStr === 'number') {
        d = new Date(dtStr);
    } else {
        // แทนที่ space ด้วย T เพื่อให้ Date parse ถูกต้องใน CEF/Safari
        d = new Date(String(dtStr).replace(' ', 'T'));
    }
    if (isNaN(d.getTime())) return '—';
    return `${d.getDate().toString().padStart(2,'0')}/${(d.getMonth()+1).toString().padStart(2,'0')}/${d.getFullYear()+543} (${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')})`;
}

function isExpiringSoon(dtStr) {
    if (!dtStr) return false;
    const d    = typeof dtStr === 'number' ? new Date(dtStr) : new Date(String(dtStr).replace(' ', 'T'));
    const diff = d - new Date();
    return diff > 0 && diff < 3 * 3600 * 1000;
}

let toastTimer = null;
function showToast(msg) {
    const el = document.getElementById('toast');
    el.textContent = msg;
    el.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.classList.remove('show'), 3000);
}

// ESC to close
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (document.getElementById('inventoryOverlay').style.display !== 'none') { closeInventory(); return; }
        if (document.getElementById('buyOverlay').style.display !== 'none') { closeBuyConfirm(); return; }
        if (document.getElementById('cancelOverlay').style.display !== 'none') { closeCancelConfirm(); return; }
        NUI.close();
    }
});
