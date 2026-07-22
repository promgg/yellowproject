/* =========================================================================
   lp_gacha — NUI front-end (2 เฟส: กล่อง+จำนวน → opening → ผลลัพธ์ grid)
   *** ไม่ตัดสินรางวัลเอง *** server สุ่ม/แจกทั้งหมด หน้านี้แค่โชว์
     - open  : รับ {pool,label,boxCount,qtyMax,items} มาตั้งค่าเฟส 1
     - spin  : ส่ง {pool,qty} กลับ server
     - result: รับ winners[] + remaining มาเล่น opening แล้วโชว์ grid
     - broadcast: โชว์แบนเนอร์ให้ทุกคน (แม้ปิดหน้าหลัก)
   ========================================================================= */

const RARITIES = {
  basic:     { c:'#be893b', g:'rgba(190,137,59,.5)' },
  common:    { c:'#cecece', g:'rgba(206,206,206,.4)' },
  uncommon:  { c:'#60cd8e', g:'rgba(96,205,142,.45)' },
  rare:      { c:'#219af9', g:'rgba(33,154,249,.5)' },
  epic:      { c:'#f921ca', g:'rgba(249,33,202,.5)' },
  legendary: { c:'#FFD700', g:'rgba(255,215,0,.55)' },
};
const RARITY_ORDER = ['basic','common','uncommon','rare','epic','legendary'];
const rarityRank = (r) => Math.max(0, RARITY_ORDER.indexOf(r));

const PLACEHOLDER_IMG = 'assets/item_placeholder.png';
const INVENTORY_IMG_BASE = 'nui://vorp_inventory/html/img/items/';
function imgSrc(image, type){
  if (!image) return PLACEHOLDER_IMG;
  if (type === 'horse') return `assets/${image}.png`;         // ม้าใช้รูปโลคอล
  return `${INVENTORY_IMG_BASE}${image}.png`;                 // item ชี้รูปกระเป๋า
}

/* ===== state ===== */
let POOL = null, ITEMS = [], boxCount = 0, QTY_MAX = 100;
let spinning = false, openTimer = null, resultBuf = null, openStart = 0;
const MIN_OPEN_MS = 1800;   // ค้าง opening อย่างน้อยเท่านี้ให้ลื่น

/* ===== dom ===== */
const $ = (id) => document.getElementById(id);
const root = $('root');
const boxCardName = $('box-card-name'), boxCard = $('box-card');
const boxCountVal = $('box-count-val');
const opening = $('opening'), openingFill = $('opening-fill'), openingPct = $('opening-pct');
const resultPanel = $('result-panel'), resultGrid = $('result-grid');
const amountInput = $('amount-input'), amountMsg = $('amount-msg'), randomBtn = $('random-btn');
const oddsBtn = $('odds-btn'), oddsList = $('odds-list'), oddsBody = $('odds-list-body');
const broadcast = $('broadcast'), broadcastText = $('broadcast-text');
let broadcastTimer = null;

/* ===================== เฟส 1: เปิดหน้า ===================== */
function openUI(data){
  POOL = data.pool;
  ITEMS = Array.isArray(data.items) ? data.items : [];
  boxCount = data.boxCount || 0;
  QTY_MAX = data.qtyMax || 100;
  boxCardName.textContent = (data.label || 'GACHA').toUpperCase();
  updateBoxCount(boxCount);

  // reset
  resultPanel.classList.add('hidden');
  opening.classList.add('hidden');
  boxCard.classList.remove('shake');
  oddsList.classList.add('hidden');
  oddsBtn.setAttribute('aria-expanded','false');
  spinning = false;
  randomBtn.disabled = false;
  clampAmount();
  renderOdds();
  root.classList.remove('hidden');
}
function closeUI(){ root.classList.add('hidden'); nui('close', {}); }
function updateBoxCount(n){ boxCount = n; boxCountVal.textContent = Number(n).toLocaleString(); }

function maxQty(){ return Math.max(1, Math.min(boxCount || 0, QTY_MAX || 100)); }
function clampAmount(){
  let v = parseInt(amountInput.value, 10);
  if (isNaN(v) || v < 1) v = 1;
  const m = maxQty();
  if (v > m) v = m;
  amountInput.value = v;
  return v;
}

/* odds list */
function renderOdds(){
  oddsBody.innerHTML = '';
  ITEMS.forEach((it) => {
    const r = RARITIES[it.rarity] || RARITIES.common;
    const row = document.createElement('div');
    row.className = 'orow';
    row.innerHTML =
      `<span class="odot" style="background:${r.c};box-shadow:0 0 8px ${r.g}"></span>` +
      `<span class="oname">${it.name || it.key}</span>` +
      `<span class="oamt">${it.chancePct != null ? it.chancePct + '%' : ''}</span>`;
    oddsBody.appendChild(row);
  });
}

/* ===================== เฟส opening ===================== */
function startOpening(){
  if (spinning) return;
  const qty = clampAmount();
  if (boxCount < 1){ flashMsg('ตั๋วไม่พอ'); return; }

  spinning = true;
  randomBtn.disabled = true;
  resultBuf = null;
  resultPanel.classList.add('hidden');
  opening.classList.remove('hidden');
  boxCard.classList.add('shake');
  openStart = Date.now();

  // หลอดวิ่งขึ้นไปหยุดแถว ~88% รอ result จริงจาก server
  let pct = 0;
  setPct(0);
  clearInterval(openTimer);
  openTimer = setInterval(() => {
    if (pct < 88){ pct += Math.max(1, (88 - pct) * 0.06); setPct(Math.min(88, pct)); }
    // ถ้า result มาแล้ว + ครบเวลาขั้นต่ำ -> ปิดจ๊อบ
    if (resultBuf && (Date.now() - openStart) >= MIN_OPEN_MS){
      clearInterval(openTimer);
      finishOpening();
    }
  }, 60);

  nui('spin', { pool: POOL, qty });
}
function setPct(p){ const v = Math.round(p); openingPct.textContent = v; openingFill.style.width = v + '%'; }

function finishOpening(){
  setPct(100);
  setTimeout(() => {
    boxCard.classList.remove('shake');
    opening.classList.add('hidden');
    revealResult(resultBuf.winners, resultBuf.remaining);
    spinning = false;
    randomBtn.disabled = false;
  }, 380);
}

/* server ส่งผลกลับ */
function handleResult(winners, remaining){
  resultBuf = { winners: winners || [], remaining: remaining };
  // ถ้ายังไม่ได้กด opening (กันเคสหลุด) หรือครบเวลาแล้ว -> จบเลย
  if (!spinning){ revealResult(resultBuf.winners, resultBuf.remaining); return; }
  if ((Date.now() - openStart) >= MIN_OPEN_MS){ clearInterval(openTimer); finishOpening(); }
}

/* ===================== เฟส 2: ผลลัพธ์ grid ===================== */
function aggregate(winners){
  const map = new Map();
  winners.forEach((w) => {
    const key = (w.type || 'item') + ':' + w.item;
    const cur = map.get(key);
    const amt = Number(w.amount) || 1;
    if (cur){ cur.total += amt; if (rarityRank(w.rarity) > rarityRank(cur.rarity)) cur.rarity = w.rarity; }
    else map.set(key, { item:w.item, image:w.image || w.item, label:w.label || w.item,
                        rarity:w.rarity || 'common', type:w.type || 'item', total:amt });
  });
  // เรียง rare -> ทั่วไป
  return [...map.values()].sort((a,b) => rarityRank(b.rarity) - rarityRank(a.rarity));
}

function revealResult(winners, remaining){
  if (remaining != null) updateBoxCount(remaining);
  const rows = aggregate(winners);
  resultGrid.innerHTML = '';
  rows.forEach((it, i) => {
    const r = RARITIES[it.rarity] || RARITIES.common;
    const hi = rarityRank(it.rarity) >= rarityRank('epic'); // epic ขึ้นไปเรืองแสง
    const card = document.createElement('div');
    card.className = 'rcard' + (hi ? ' rare-hi' : '');
    card.style.setProperty('--rc', r.c);
    card.style.setProperty('--rg', r.g);
    card.style.setProperty('--d', (i * 0.04) + 's');
    card.innerHTML =
      `<div class="rc-name">${it.label}</div>` +
      `<div class="rc-img"><img src="${imgSrc(it.image, it.type)}" alt="" ` +
        `onerror="this.onerror=null;this.src='${PLACEHOLDER_IMG}'"></div>` +
      `<div class="rc-count">x${Number(it.total).toLocaleString()}</div>`;
    resultGrid.appendChild(card);
  });
  resultPanel.classList.remove('hidden');
}

/* ===================== broadcast ===================== */
function showBroadcast(text){
  if (!text) return;
  broadcastText.textContent = text;
  broadcast.classList.remove('hidden','out');
  // retrigger animation
  void broadcast.offsetWidth;
  clearTimeout(broadcastTimer);
  broadcastTimer = setTimeout(() => {
    broadcast.classList.add('out');
    setTimeout(() => broadcast.classList.add('hidden'), 400);
  }, 6000);
}

/* ===================== ui helpers ===================== */
function flashMsg(msg){
  amountMsg.textContent = msg;
  amountMsg.classList.remove('hidden');
  clearTimeout(flashMsg._t);
  flashMsg._t = setTimeout(() => amountMsg.classList.add('hidden'), 1800);
}

/* ===================== events ===================== */
randomBtn.addEventListener('click', startOpening);
amountInput.addEventListener('change', clampAmount);
amountInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') startOpening(); });
oddsBtn.addEventListener('click', () => {
  const open = oddsList.classList.toggle('hidden') === false;
  oddsBtn.setAttribute('aria-expanded', String(open));
});
$('close-btn').addEventListener('click', closeUI);
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !root.classList.contains('hidden')) closeUI();
});

/* ===================== NUI bridge ===================== */
function nui(name, payload){
  const resName = (window.GetParentResourceName && GetParentResourceName()) || 'lp_gacha';
  fetch(`https://${resName}/${name}`, {
    method:'POST', headers:{ 'Content-Type':'application/json; charset=UTF-8' },
    body:JSON.stringify(payload || {}),
  }).catch(() => {});
}

window.addEventListener('message', (ev) => {
  const data = ev.data || {};
  switch (data.action){
    case 'open':      openUI(data.data || {}); break;
    case 'result':    handleResult(data.winners, data.remaining); break;
    case 'rejected':
      spinning = false; randomBtn.disabled = false;
      clearInterval(openTimer);
      boxCard.classList.remove('shake'); opening.classList.add('hidden');
      flashMsg(data.reason === 'cooldown' ? 'รอสักครู่' : 'ตั๋วไม่พอ');
      break;
    case 'broadcast': showBroadcast(data.text); break;   // โชว์ได้แม้ปิดหน้าหลัก
    case 'close':     root.classList.add('hidden'); break;
  }
});

/* DEV ONLY — mock เมื่อเปิดตรงในเบราว์เซอร์ */
if (window.location.protocol !== 'nui:' && window.location.protocol !== 'https:'){
  openUI({
    pool:'promo', label:'กาชาโปรโมทเซิร์ฟ', boxCount:9999, qtyMax:100,
    items:[
      { key:'food_bread', name:'ขนมปัง', image:'food_bread', rarity:'basic', amount:5, chancePct:17.6 },
      { key:'mat_diamond', name:'เพชร', image:'mat_diamond', rarity:'rare', amount:2, chancePct:8.6 },
      { key:'aed', name:'กล่องชุบเพื่อน', image:'aed', rarity:'epic', amount:1, chancePct:5 },
      { key:'horse', name:'ม้า Suffolk Punch', image:'a_c_horse_suffolkpunch_sorrel', rarity:'legendary', amount:1, chancePct:2 },
    ],
  });
  // mock ปุ่ม random -> ส่งผลปลอมกลับ
  window.__mockResult = () => handleResult([
    { item:'food_bread', label:'ขนมปัง', image:'food_bread', rarity:'basic', amount:5, type:'item' },
    { item:'food_bread', label:'ขนมปัง', image:'food_bread', rarity:'basic', amount:5, type:'item' },
    { item:'mat_diamond', label:'เพชร', image:'mat_diamond', rarity:'rare', amount:2, type:'item' },
    { item:'aed', label:'กล่องชุบเพื่อน', image:'aed', rarity:'epic', amount:1, type:'item' },
    { item:'a_c_horse_suffolkpunch_sorrel', label:'ม้า Suffolk Punch', image:'a_c_horse_suffolkpunch_sorrel', rarity:'legendary', amount:1, type:'horse' },
  ], 9994);
  const _orig = nui;
  window.nui = (n,p) => { if (n === 'spin') setTimeout(window.__mockResult, 900); };
  randomBtn.addEventListener('click', () => setTimeout(window.__mockResult, 900));
  setTimeout(() => showBroadcast('คุณ JAME GARCIA ได้รับ ม้า Suffolk Punch'), 400);
}
