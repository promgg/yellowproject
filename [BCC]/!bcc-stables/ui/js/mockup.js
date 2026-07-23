const horses = [
  {
    name: 'ซิลเวอร์', breed: 'Missouri Fox Trotter', coat: 'Silver Dapple Pinto', gender: 'เพศผู้',
    bond: 4, health: 92, stamina: 78, cargo: '30 / 40 ช่อง',
    status: 'ม้าหลัก · อยู่ในคอก', tone: 'ready', primary: 'เรียกม้าตัวนี้', primaryHelp: 'ออกจากคอกม้า',
    stats: [8, 8, 9, 8, 7, 8]
  },
  {
    name: 'แบล็คเบิร์ด', breed: 'American Standardbred', coat: 'Black', gender: 'เพศเมีย',
    bond: 3, health: 100, stamina: 88, cargo: '12 / 35 ช่อง',
    status: 'ถูกเรียกอยู่ · Valentine', tone: 'ready', primary: 'เก็บม้าเข้าคอก', primaryHelp: 'ม้าอยู่ใกล้ Valentine',
    stats: [6, 7, 8, 9, 8, 6]
  },
  {
    name: 'คอปเปอร์', breed: 'Hungarian Halfbred', coat: 'Flaxen Chestnut', gender: 'เพศผู้',
    bond: 2, health: 36, stamina: 54, cargo: '40 / 45 ช่อง',
    status: 'บาดเจ็บ · เรียกใช้งานไม่ได้', tone: 'danger', primary: 'ดูแลม้าตัวนี้', primaryHelp: 'รักษาก่อนเรียกใช้งาน',
    stats: [9, 8, 6, 5, 5, 9]
  }
];

const tackCatalog = {
  saddle: [
    { name: 'Gerden Trail Saddle', price: 180 }, { name: 'Lumley Ranch Cutter', price: 220 },
    { name: 'Kneller Mother Hubbard', price: 260 }, { name: 'ไม่มีอาน', price: 0 }
  ],
  bag: [
    { name: 'Collector Saddle Bag', price: 95 }, { name: 'Leather Saddle Bag', price: 70 },
    { name: 'Canvas Saddle Bag', price: 45 }, { name: 'ไม่ใส่กระเป๋า', price: 0 }
  ],
  blanket: [
    { name: 'Wool Blanket', price: 35 }, { name: 'Bearskin Blanket', price: 85 },
    { name: 'Patterned Blanket', price: 55 }, { name: 'ไม่ใส่ผ้ารอง', price: 0 }
  ],
  stirrup: [
    { name: 'Safety Stirrup', price: 60 }, { name: 'Deep Roper Stirrup', price: 90 },
    { name: 'Slim-line Stirrup', price: 75 }, { name: 'Standard Stirrup', price: 25 }
  ]
};

const statNames = ['พลังชีวิต', 'พละกำลัง', 'ความเร็ว', 'อัตราเร่ง', 'ความคล่องตัว', 'ความกล้าหาญ'];
const statIcons = ['fa-heart', 'fa-bolt', 'fa-gauge-high', 'fa-forward-fast', 'fa-person-running', 'fa-shield-halved'];
const cash = 4280;
const root = document.querySelector('#stable-ui');
const mockupParams = new URLSearchParams(window.location.search);
let page = mockupParams.get('page') === 'shop' ? 'shop' : 'owned';
let horseIndex = 0;
let shopBreedIndex = Math.max(0, horseShopCatalog.findIndex(item => item.breed === 'Missouri Fox Trotter'));
let shopColorIndex = Math.max(0, horseShopCatalog[shopBreedIndex].colors.findIndex(item => item.color === 'Silver Dapple Pinto'));
let shopSearch = '';
let shopPickerStep = 'breeds';
let view = page === 'owned' && mockupParams.get('view') === 'tack' ? 'tack' : 'home';
let rosterFilter = 'all';
let tackCategory = 'saddle';
const selectedTack = {
  saddle: tackCatalog.saddle[0], bag: tackCatalog.bag[0],
  blanket: tackCatalog.blanket[0], stirrup: tackCatalog.stirrup[0]
};

function byId(id) { return document.getElementById(id); }
function ticks(value) {
  return `<span class="ticks">${Array.from({ length: 10 }, (_, index) => `<i class="${index < value ? 'on' : ''}"></i>`).join('')}</span>`;
}
function renderStats(values, targetId = 'base-stats', offset = 0) {
  byId(targetId).innerHTML = values.map((value, index) => `
    <div class="base-stat"><i class="fa-solid ${statIcons[index + offset]}"></i><span>${statNames[index + offset]}</span><b>${value}/10</b>${ticks(value)}</div>
  `).join('');
}
function renderRoster() {
  const visibleHorses = horses.map((horse, index) => ({ horse, index })).filter(({ horse }) => {
    if (rosterFilter === 'all') return true;
    return rosterFilter === 'danger' ? horse.tone === 'danger' : horse.tone !== 'danger';
  });
  byId('roster-list').innerHTML = visibleHorses.map(({ horse, index }) => `
    <button class="roster-card ${index === horseIndex ? 'selected' : ''}" data-horse-choice="${index}" data-tone="${horse.tone}" type="button">
      <i class="fa-solid fa-horse-head"></i>
      <span><strong>${horse.name}</strong><small>${horse.breed} · Lv. ${horse.bond}</small></span>
      <b>${horse.status.split(' · ')[0]}</b>
    </button>
  `).join('');
  document.querySelectorAll('[data-horse-choice]').forEach(button => button.addEventListener('click', () => {
    horseIndex = Number(button.dataset.horseChoice);
    render();
  }));
}
function renderTackItems() {
  const items = tackCatalog[tackCategory];
  byId('tack-item-list').innerHTML = items.map((item, index) => `
    <button class="tack-item ${selectedTack[tackCategory].name === item.name ? 'selected' : ''}" data-tack-index="${index}" type="button">
      <i class="tack-swatch"></i><strong>${item.name}</strong><small>${item.price ? `$${item.price}` : 'ถอดออก'}</small>
    </button>
  `).join('');
  document.querySelectorAll('[data-tack-index]').forEach(button => button.addEventListener('click', () => {
    selectedTack[tackCategory] = items[Number(button.dataset.tackIndex)];
    renderTackSummary();
    renderTackItems();
  }));
}
function renderTackSummary() {
  const total = Object.values(selectedTack).reduce((sum, item) => sum + item.price, 0);
  Object.entries(selectedTack).forEach(([category, item]) => {
    byId(`equipped-${category}`).textContent = item.name;
    byId(`equipped-${category}-price`).textContent = item.price ? `$${item.price}` : '—';
  });
  byId('tack-total').textContent = `$${total.toLocaleString('en-US')}`;
}
function shopStats(index) {
  return [6 + (index % 4), 6 + ((index + 1) % 4), 5 + ((index + 2) % 5), 5 + ((index + 3) % 5), 6 + ((index + 1) % 4), 6 + ((index + 2) % 4)];
}
function selectedShopItem() {
  const breed = horseShopCatalog[shopBreedIndex];
  const color = breed.colors[shopColorIndex] || breed.colors[0];
  return { ...color, name: color.color, breed: breed.breed, coat: color.color, stats: shopStats(shopBreedIndex) };
}
function coatGradient(index) {
  const palettes = [
    ['#211b16', '#7c6c58'], ['#23150d', '#9a6335'], ['#151515', '#69645f'],
    ['#5d3b24', '#d2b17b'], ['#3d2e27', '#8d8277'], ['#281b17', '#b68b66']
  ];
  const colors = palettes[index % palettes.length];
  return `linear-gradient(135deg, ${colors[0]}, ${colors[1]})`;
}
function renderShopBrowser() {
  const query = shopSearch.trim().toLowerCase();
  const breeds = horseShopCatalog.map((item, index) => ({ item, index })).filter(({ item }) => item.breed.toLowerCase().includes(query));
  const selectingColors = shopPickerStep === 'colors';
  document.querySelector('.catalog-search').hidden = selectingColors;
  byId('catalog-back').hidden = !selectingColors;
  byId('breed-list').hidden = selectingColors;
  byId('color-list').hidden = !selectingColors;
  byId('catalog-step').textContent = selectingColors ? 'ขั้นตอน 2 จาก 2' : 'ขั้นตอน 1 จาก 2';
  byId('catalog-title').textContent = selectingColors ? horseShopCatalog[shopBreedIndex].breed : 'เลือกสายพันธุ์';
  byId('breed-list').innerHTML = breeds.length ? breeds.map(({ item, index }) => `
    <button class="breed-card ${index === shopBreedIndex ? 'selected' : ''}" data-breed-index="${index}" type="button">
      <i class="fa-solid fa-horse-head"></i><span>${item.breed}</span><b>${item.colors.length} สี</b>
    </button>
  `).join('') : '<div class="catalog-empty"><i class="fa-solid fa-magnifying-glass"></i><span>ไม่พบสายพันธุ์ที่ค้นหา</span></div>';
  document.querySelectorAll('[data-breed-index]').forEach(button => button.addEventListener('click', () => {
    shopBreedIndex = Number(button.dataset.breedIndex);
    shopColorIndex = 0;
    shopPickerStep = 'colors';
    render();
  }));
  const selectedBreed = horseShopCatalog[shopBreedIndex];
  byId('color-count').textContent = selectingColors ? `${selectedBreed.colors.length} สี` : `${breeds.length} รายการ`;
  byId('color-list').innerHTML = selectedBreed.colors.map((item, index) => `
    <button class="color-card ${index === shopColorIndex ? 'selected' : ''}" data-color-index="${index}" type="button">
      <i class="coat-swatch" style="--coat:${coatGradient(index)}"></i>
      <span><strong>${item.color}</strong><small>$${item.cash.toLocaleString('en-US')}</small></span>
    </button>
  `).join('');
  document.querySelectorAll('[data-color-index]').forEach(button => button.addEventListener('click', () => {
    shopColorIndex = Number(button.dataset.colorIndex);
    render();
  }));
}
function setView(nextView) {
  view = nextView;
  root.dataset.view = view;
  if (view === 'tack') { renderTackItems(); renderTackSummary(); }
}
function updateTabs() {
  root.dataset.page = page;
  document.querySelectorAll('[data-page-target]').forEach(button => {
    button.classList.toggle('active', button.dataset.pageTarget === page);
    button.setAttribute('aria-current', button.dataset.pageTarget === page ? 'page' : 'false');
  });
}
function renderOwned(item) {
  byId('horse-name').textContent = item.name;
  byId('horse-meta').textContent = `${item.coat} · ${item.gender} · ความผูกพัน Lv. ${item.bond}`;
  byId('profile-bond').textContent = `ระดับ ${item.bond}`;
  byId('profile-cargo').textContent = item.cargo;
  byId('profile-status').innerHTML = `<i></i> ${item.status}`;
  byId('profile-status').dataset.tone = item.tone;
  byId('health-value').textContent = `${item.health}%`;
  byId('stamina-value').textContent = `${item.stamina}%`;
  byId('health-bar').style.width = `${item.health}%`;
  byId('stamina-bar').style.width = `${item.stamina}%`;
  byId('primary-label').textContent = item.primary;
  byId('primary-help').textContent = item.primaryHelp;
}
function renderShop(item) {
  byId('horse-name').textContent = item.name;
  byId('horse-meta').textContent = `${item.breed} · ${item.coat}`;
  byId('summary-breed').textContent = item.breed;
  byId('summary-coat').textContent = item.coat;
  byId('shop-price').textContent = `$${item.cash.toLocaleString('en-US')}`;
  byId('shop-balance').textContent = `$${(cash - item.cash).toLocaleString('en-US')}`;
  byId('purchase-total-price').textContent = `$${item.cash.toLocaleString('en-US')}`;
}
function render() {
  updateTabs();
  const item = page === 'owned' ? horses[horseIndex] : selectedShopItem();
  byId('horse-breed').textContent = item.breed.toUpperCase();
  if (page === 'owned') { renderStats(item.stats); renderOwned(item); }
  else { renderStats(item.stats.slice(2), 'shop-base-stats', 2); renderShop(item); }
  if (page === 'owned') renderRoster();
  if (page === 'shop') renderShopBrowser();
  if (view === 'tack') { renderTackItems(); renderTackSummary(); }
}
function setPage(nextPage) {
  page = nextPage;
  if (page === 'shop') shopPickerStep = 'breeds';
  setView('home');
  document.querySelectorAll('.action-card').forEach(card => card.classList.remove('selected'));
  const firstAction = document.querySelector(`.${page === 'owned' ? 'owned-only' : 'shop-only'} .action-card`);
  if (firstAction) firstAction.classList.add('selected');
  render();
}
document.querySelectorAll('[data-page-target]').forEach(button => button.addEventListener('click', () => setPage(button.dataset.pageTarget)));
document.querySelectorAll('[data-open-view]').forEach(button => button.addEventListener('click', () => setView(button.dataset.openView)));
document.querySelectorAll('[data-close-view]').forEach(button => button.addEventListener('click', () => setView('home')));
document.querySelectorAll('[data-roster-filter]').forEach(button => button.addEventListener('click', () => {
  rosterFilter = button.dataset.rosterFilter;
  document.querySelectorAll('[data-roster-filter]').forEach(chip => chip.classList.toggle('active', chip === button));
  renderRoster();
}));
document.querySelectorAll('[data-tack-category]').forEach(button => button.addEventListener('click', () => {
  tackCategory = button.dataset.tackCategory;
  document.querySelectorAll('[data-tack-category]').forEach(tab => tab.classList.toggle('active', tab === button));
  renderTackItems();
}));
byId('breed-search').addEventListener('input', event => { shopSearch = event.target.value; renderShopBrowser(); });
byId('catalog-back').addEventListener('click', () => { shopPickerStep = 'breeds'; renderShopBrowser(); });
document.querySelectorAll('.action-card').forEach(button => button.addEventListener('click', () => {
  button.closest('.action-rail').querySelectorAll('.action-card').forEach(card => card.classList.remove('selected'));
  button.classList.add('selected');
  if (button.dataset.action === 'tack') setView('tack');
}));
byId('save-tack').addEventListener('click', () => setView('home'));
document.querySelector('.back-button').addEventListener('click', () => { if (view !== 'home') setView('home'); });
document.addEventListener('keydown', event => {
  const key = event.key.toLowerCase();
  if (event.key === 'Escape' && view !== 'home') { setView('home'); return; }
  if (event.key === '1') setPage('owned');
  if (event.key === '2') setPage('shop');
});

root.dataset.view = view;
render();
