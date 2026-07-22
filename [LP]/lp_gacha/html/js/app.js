/* =========================================================================
   lp_gacha NUI — Single Slim Panel
   *** ไม่ตัดสินรางวัลเอง *** server สุ่ม/แจกทั้งหมด หน้านี้แค่โชว์
     open      : {pool,label,ticket,boxCount,qtyMax,items} → ตั้งค่าเฟส 1 + droplist
     spin      : ส่ง {pool,qty} กลับ server
     result    : winners[] + remaining → เล่น opening → เผยการ์ดสุ่มเลขทีละใบ (ต่ำ→สูง)
     revealDone: เมื่อเผยจบ ส่งกลับ server ให้แจกของ (grant ตอนนี้ ไม่ใช่ก่อนเผย)
     broadcast : โชว์ banner ให้ทุกคน (แม้ปิดหน้าหลัก)
   ========================================================================= */

const RARITIES = {
  basic:     ['#c08a3e','rgba(192,138,62,.5)','ธรรมดา'],
  common:    ['#cfcfcf','rgba(207,207,207,.45)','ทั่วไป'],
  uncommon:  ['#6fce97','rgba(111,206,151,.5)','พิเศษ'],
  rare:      ['#4aa3f0','rgba(74,163,240,.6)','หายาก'],
  epic:      ['#d879ef','rgba(216,121,239,.6)','เอปิก'],
  legendary: ['#f2c73d','rgba(242,199,61,.7)','ตำนาน'],
};
const RANK = ['basic','common','uncommon','rare','epic','legendary'];
const rank = r => Math.max(0, RANK.indexOf(r));

const PLACEHOLDER = 'assets/item_placeholder.png';
const INV_BASE = 'nui://vorp_inventory/html/img/items/';
// horse = รูปโลคอลของ lp_gacha, item/อื่น ๆ = รูปกระเป๋าจริง (เหมือนของเดิม)
function imgSrc(image, type){
  if (!image) return PLACEHOLDER;
  if (type === 'horse') return `assets/${image}.png`;
  return `${INV_BASE}${image}.png`;
}

/* ===== state ===== */
let POOL = null, ITEMS = [], boxCount = 0, QTY_MAX = 100;
let spinning = false;
const MIN_OPEN_MS = 900;

/* ===== dom ===== */
const $ = id => document.getElementById(id);
const root=$('root'), panel=$('panel'), grid=$('grid'), fill=$('open-fill'), pct=$('pct'),
      box=$('box'), boxImg=$('box-img'), boxName=$('box-name'), ttl=$('ttl'), cntVal=$('cnt-val'),
      amt=$('amt'), msg=$('msg'), randomBtn=$('random-btn'), spot=$('spot'), summary=$('summary'),
      dl=$('droplist'), dlBody=$('dl-body'), infoBtn=$('info-btn'),
      broadcast=$('broadcast'), bcText=$('bc-text');
let bcTimer=null;

/* ===================== open ===================== */
function openUI(data){
  POOL = data.pool;
  ITEMS = Array.isArray(data.items) ? data.items : [];
  boxCount = data.boxCount || 0;
  QTY_MAX = data.qtyMax || 100;
  ttl.textContent = 'GACHAPON';
  boxName.textContent = (data.label || 'GACHA').toUpperCase();
  // box = รูปตั๋วจริง (ถ้ามี ticket ใน payload) ไม่งั้น placeholder
  boxImg.style.display = '';
  boxImg.src = data.ticket ? imgSrc(data.ticket, 'item') : PLACEHOLDER;
  updateCount(boxCount);
  renderDroplist();
  clampAmt();
  // reset
  grid.innerHTML = '<div class="empty">— กด RANDOM เพื่อเปิดกล่อง —</div>';
  summary.classList.remove('show'); summary.innerHTML='';
  spot.classList.remove('show'); fill.style.width='0%'; pct.textContent='0';
  box.classList.remove('shake');
  dl.classList.add('hidden'); infoBtn.setAttribute('aria-expanded','false');
  msg.classList.add('hidden');
  spinning=false; randomBtn.disabled=false;
  root.classList.remove('hidden');
}
function closeUI(){ root.classList.add('hidden'); nui('close',{}); }
function updateCount(n){ boxCount=n; cntVal.textContent = Number(n).toLocaleString(); }
function maxQty(){ return Math.max(1, Math.min(boxCount||0, QTY_MAX||100)); }
function clampAmt(){ let v=parseInt(amt.value,10); if(isNaN(v)||v<1)v=1; const m=maxQty(); if(v>m)v=m; amt.value=v; return v; }

function renderDroplist(){
  dlBody.innerHTML='';
  ITEMS.forEach(it=>{
    const [c] = RARITIES[it.rarity] || RARITIES.common;
    const row=document.createElement('div'); row.className='drow';
    row.innerHTML =
      `<span class="ddot" style="background:${c}"></span>` +
      `<span class="di"><img src="${imgSrc(it.image,it.type)}" onerror="this.onerror=null;this.src='${PLACEHOLDER}'"></span>` +
      `<span class="dn">${it.name||it.key}</span>` +
      `<span class="dp" style="color:${c}">${it.chancePct!=null?(Math.round(it.chancePct*100)/100)+'%':''}</span>`;
    dlBody.appendChild(row);
  });
}

/* ===================== spin ===================== */
function startSpin(){
  if(spinning) return;
  const qty=clampAmt();
  if(boxCount<1){ flashMsg('ตั๋วไม่พอ'); return; }
  spinning=true; randomBtn.disabled=true;
  grid.innerHTML=''; summary.classList.remove('show'); spot.classList.remove('show');
  box.classList.add('shake');
  // opening bar เดินไปหยุด ~88% รอ result
  let p=0; setPct(0);
  clearInterval(startSpin._iv);
  startSpin._iv=setInterval(()=>{ if(p<88){ p+=Math.max(2,(88-p)*.08); setPct(Math.min(88,p)); } },55);
  startSpin._t0=Date.now();
  nui('spin',{ pool:POOL, qty });
}
function setPct(p){ const v=Math.round(p); pct.textContent=v; fill.style.width=v+'%'; }

/* server ส่งผลกลับ → เล่นเผย */
async function handleResult(winners, remaining){
  if(remaining!=null) updateCount(remaining);
  // ให้ opening ครบขั้นต่ำก่อน
  const wait = Math.max(0, MIN_OPEN_MS - (Date.now()-(startSpin._t0||0)));
  await sleep(wait);
  clearInterval(startSpin._iv); setPct(100);
  await sleep(280);
  box.classList.remove('shake');

  const rows = aggregate(winners||[]);       // รวบชนิดเดียวกัน
  const show = rows.slice(0,10);
  let total=0;
  for(let i=0;i<show.length;i++){
    const it=show[i]; const [c,g,lbl]=RARITIES[it.rarity]||RARITIES.common;
    const card=document.createElement('div'); card.className='card2';
    card.style.setProperty('--cc','var(--hair)'); card.style.setProperty('--cg','transparent');
    card.innerHTML=`<div class="badge"></div><div class="ic"><img src="${imgSrc(it.image,it.type)}" onerror="this.onerror=null;this.src='${PLACEHOLDER}'"></div>`+
      `<div class="nm">${it.label}</div><div class="ct rolling">×0</div>`;
    grid.appendChild(card); requestAnimationFrame(()=>card.classList.add('in'));
    const ctEl=card.querySelector('.ct');
    // สุ่มเฉพาะ "ตัวเลข" — ยิ่ง rare ยิ่งวิ่งนาน
    const shuffleMs=380+rank(it.rarity)*170, hi=Math.max(3,it.total*3), t0=performance.now();
    await new Promise(done=>{ const sh=setInterval(()=>{ ctEl.textContent='×'+(1+Math.floor(Math.random()*hi));
      if(performance.now()-t0>=shuffleMs){ clearInterval(sh); done(); } },55); });
    ctEl.classList.remove('rolling'); ctEl.textContent='×'+it.total;
    card.style.setProperty('--cc',c); card.style.setProperty('--cg',g);
    const bd=card.querySelector('.badge'); bd.textContent=lbl; bd.style.background=c;
    card.classList.add('lock'); total+=it.total;
    card.style.transform='scale(1.08)'; setTimeout(()=>{ card.style.transform='none'; },150);
    if(rank(it.rarity)>=rank('epic')){ spot.textContent='★ '+lbl+'! '+it.label+' ★'; spot.classList.remove('show'); void spot.offsetWidth; spot.classList.add('show'); }
    await sleep(190);
  }
  const best = show.length ? show[show.length-1] : null; // ต่ำ→สูง = ตัวสุดท้ายหายากสุด
  summary.innerHTML = best ? `ได้ทั้งหมด <b>${total.toLocaleString()}</b> ชิ้น · ${show.length} ชนิด · หายากสุด <span class="best">${best.label}</span>` : '';
  summary.classList.add('show');
  spinning=false; randomBtn.disabled=false;

  // เผยจบแล้ว → บอก server ให้แจกของตอนนี้ (grant หลังเผย ไม่สปอยล์)
  nui('revealDone',{});
}

function aggregate(winners){
  const m=new Map();
  winners.forEach(w=>{ const k=(w.type||'item')+':'+w.item; const cur=m.get(k); const a=Number(w.amount)||1;
    if(cur){ cur.total+=a; if(rank(w.rarity)>rank(cur.rarity)) cur.rarity=w.rarity; }
    else m.set(k,{ item:w.item, image:w.image||w.item, label:w.label||w.item, rarity:w.rarity||'common', type:w.type||'item', total:a }); });
  return [...m.values()].sort((a,b)=>rank(a.rarity)-rank(b.rarity)); // ต่ำ→สูง
}

/* ===================== broadcast ===================== */
function showBroadcast(text){
  if(!text) return;
  bcText.textContent=text; broadcast.classList.remove('hidden','out'); void broadcast.offsetWidth;
  clearTimeout(bcTimer);
  bcTimer=setTimeout(()=>{ broadcast.classList.add('out'); setTimeout(()=>broadcast.classList.add('hidden'),400); },6000);
}

/* ===================== helpers ===================== */
const sleep = ms => new Promise(r=>setTimeout(r,ms));
function flashMsg(t){ msg.textContent=t; msg.classList.remove('hidden'); clearTimeout(flashMsg._t); flashMsg._t=setTimeout(()=>msg.classList.add('hidden'),1800); }

/* ===================== events ===================== */
randomBtn.addEventListener('click', startSpin);
amt.addEventListener('change', clampAmt);
amt.addEventListener('keydown', e=>{ if(e.key==='Enter') startSpin(); });
$('btn-min').addEventListener('click', ()=>{ amt.value=1; });
$('btn-max').addEventListener('click', ()=>{ amt.value=maxQty(); });
infoBtn.addEventListener('click', ()=>{ const on=dl.classList.toggle('hidden')===false; infoBtn.setAttribute('aria-expanded',String(on)); });
$('close-btn').addEventListener('click', closeUI);
document.addEventListener('keydown', e=>{ if(e.key==='Escape' && !root.classList.contains('hidden')) closeUI(); });

/* ===================== NUI bridge ===================== */
function nui(name, payload){
  const res=(window.GetParentResourceName&&GetParentResourceName())||'lp_gacha';
  fetch(`https://${res}/${name}`,{ method:'POST', headers:{'Content-Type':'application/json; charset=UTF-8'}, body:JSON.stringify(payload||{}) }).catch(()=>{});
}
window.addEventListener('message', ev=>{
  const d=ev.data||{};
  switch(d.action){
    case 'open':      openUI(d.data||{}); break;
    case 'result':    handleResult(d.winners, d.remaining); break;
    case 'rejected':  spinning=false; randomBtn.disabled=false; clearInterval(startSpin._iv);
                      box.classList.remove('shake'); fill.style.width='0%'; pct.textContent='0';
                      flashMsg(d.reason==='cooldown'?'รอสักครู่':'ตั๋วไม่พอ'); break;
    case 'broadcast': showBroadcast(d.text); break;
    case 'close':     root.classList.add('hidden'); break;
  }
});

/* DEV mock (เปิดตรงในเบราว์เซอร์) */
if(window.location.protocol!=='nui:' && window.location.protocol!=='https:'){
  openUI({ pool:'promo', label:'กาชาโปรโมทเซิร์ฟ', ticket:'gacha_promo', boxCount:9999, qtyMax:100,
    items:[
      {key:'food_bread',name:'ขนมปัง',image:'food_bread',type:'item',rarity:'basic',chancePct:17.6},
      {key:'mat_diamond',name:'เพชร',image:'mat_diamond',type:'item',rarity:'rare',chancePct:8.6},
      {key:'aed',name:'กล่องชุบเพื่อน',image:'aed',type:'item',rarity:'epic',chancePct:5},
      {key:'a_c_horse_suffolkpunch_sorrel',name:'ม้า Suffolk Punch',image:'a_c_horse_suffolkpunch_sorrel',type:'horse',rarity:'legendary',chancePct:20},
    ]});
  window.nui=(n)=>{ if(n==='spin') setTimeout(()=>handleResult([
    {item:'food_bread',label:'ขนมปัง',image:'food_bread',rarity:'basic',amount:5,type:'item'},
    {item:'food_bread',label:'ขนมปัง',image:'food_bread',rarity:'basic',amount:5,type:'item'},
    {item:'mat_diamond',label:'เพชร',image:'mat_diamond',rarity:'rare',amount:2,type:'item'},
    {item:'aed',label:'กล่องชุบเพื่อน',image:'aed',rarity:'epic',amount:1,type:'item'},
    {item:'a_c_horse_suffolkpunch_sorrel',label:'ม้า Suffolk Punch',image:'a_c_horse_suffolkpunch_sorrel',rarity:'legendary',amount:1,type:'horse'},
  ], 9994), 700); };
}
