const isNui = typeof GetParentResourceName === 'function';
const resourceName = isNui ? GetParentResourceName() : 'nx_shop';

const mockStore = {
    id: 'Blackwater',
    title: 'ร้านค้า',
    subtitle: 'BLACKWATER STORE',
    categories: [
        { id: 'all', label: 'ALL' },
        { id: 'food', label: 'FOOD' },
        { id: 'tools', label: 'WORK EQUIPMENT' },
        { id: 'supplies', label: 'SUPPLIES' }
    ],
    payment: {
        allowCash: true,
        allowBank: true,
        vatPercent: 7
    },
    items: [
        { id: 'bread', label: 'Bread', category: 'food', price: 1000, currency: 'cash', image: 'bread.png', max: 99 },
        { id: 'water', label: 'Water', category: 'food', price: 1000, currency: 'cash', image: 'water.png', max: 99 },
        { id: 'apple', label: 'Apple', category: 'food', price: 1000, currency: 'cash', image: 'apple.png', max: 99 },
        { id: 'pickaxe', label: 'Pickaxe', category: 'tools', price: 1000, currency: 'cash', image: 'pickaxe.png', max: 99 },
        { id: 'axe', label: 'Axe', category: 'tools', price: 1000, currency: 'cash', image: 'axe.png', max: 99 },
        { id: 'coal', label: 'Coal', category: 'supplies', price: 350, currency: 'cash', image: 'coal.png', max: 99 },
        { id: 'wood', label: 'Wood', category: 'supplies', price: 250, currency: 'cash', image: 'wood.png', max: 99 },
        { id: 'black_money', label: 'Contraband', category: 'supplies', price: 500, currency: 'black', image: 'black_money.png', max: 99 }
    ]
};

const state = {
    open: false,
    store: null,
    items: [],
    categories: [],
    activeCategory: 'all',
    cart: new Map(),
    imagePath: '',
    pending: false
};

const els = {
    shop: document.getElementById('shop'),
    title: document.getElementById('shopTitle'),
    subtitle: document.getElementById('shopSubtitle'),
    categories: document.getElementById('categories'),
    items: document.getElementById('items'),
    cart: document.getElementById('cart'),
    cashTotal: document.getElementById('cashTotal'),
    blackTotal: document.getElementById('blackTotal'),
    useBank: document.getElementById('useBank'),
    bankLabel: document.getElementById('bankLabel'),
    payBtn: document.getElementById('payBtn'),
    cancelBtn: document.getElementById('cancelBtn')
};

function updateShopScale() {
    const scale = Math.min(window.innerWidth / 900, window.innerHeight / 860, 1);
    document.documentElement.style.setProperty('--shop-scale', scale.toFixed(3));
}

function post(name, data = {}) {
    if (!isNui) {
        if (name === 'pay') {
            window.setTimeout(() => {
                window.dispatchEvent(new MessageEvent('message', {
                    data: {
                        action: 'purchaseResult',
                        result: { ok: false, message: 'Mock mode: no server payment' }
                    }
                }));
            }, 350);
        }

        return Promise.resolve({ ok: true, mock: true, data });
    }

    return fetch(`https://${resourceName}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(() => null);
}

function formatMoney(value) {
    const number = Number(value) || 0;
    return number.toLocaleString('en-US', {
        minimumFractionDigits: number % 1 === 0 ? 0 : 2,
        maximumFractionDigits: 2
    });
}

function imageUrl(item) {
    if (!item.image) return '';
    if (/^(https?:|nui:|\.\/|\/)/.test(item.image)) return item.image;
    return `${state.imagePath}${item.image}`;
}

function totals() {
    let cash = 0;
    let black = 0;

    for (const [id, qty] of state.cart.entries()) {
        const item = state.items.find((entry) => entry.id === id);
        if (!item) continue;

        const total = (Number(item.price) || 0) * qty;
        if (item.currency === 'black') black += total;
        else cash += total;
    }

    const vatPercent = Number(state.store?.payment?.vatPercent) || 0;
    const vat = els.useBank.checked ? cash * (vatPercent / 100) : 0;

    return { cash, black, vat, charge: cash + vat, vatPercent };
}

function renderCategories() {
    els.categories.innerHTML = '';

    state.categories.forEach((category) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = category.id === state.activeCategory ? 'active' : '';
        button.textContent = category.label;
        button.addEventListener('click', () => {
            state.activeCategory = category.id;
            render();
        });
        els.categories.appendChild(button);
    });
}

function renderItems() {
    els.items.innerHTML = '';

    const filtered = state.items.filter((item) => state.activeCategory === 'all' || item.category === state.activeCategory);

    filtered.forEach((item) => {
        const qty = state.cart.get(item.id) || 0;
        const card = document.createElement('button');
        card.type = 'button';
        card.className = qty > 0 ? 'item-card selected' : 'item-card';
        card.innerHTML = `
            <span class="item-name">${item.label}</span>
            <img src="${imageUrl(item)}" alt="">
            <strong>${formatMoney(item.price)}</strong>
        `;
        card.addEventListener('click', () => addItem(item.id, 1));
        els.items.appendChild(card);
    });
}

function renderCart() {
    els.cart.innerHTML = '';

    const entries = Array.from(state.cart.entries());
    const visibleRows = Math.max(entries.length, 5);

    for (let index = 0; index < visibleRows; index += 1) {
        const row = document.createElement('div');
        const entry = entries[index];

        if (!entry) {
            row.className = 'cart-empty-slot';
            els.cart.appendChild(row);
            continue;
        }

        const [id, qty] = entry;
        const item = state.items.find((candidate) => candidate.id === id);
        if (!item) continue;

        row.className = 'cart-item';
        row.innerHTML = `
            <img src="${imageUrl(item)}" alt="">
            <div class="cart-info">
                <b>${item.label}</b>
                <span>${formatMoney((Number(item.price) || 0) * qty)}</span>
            </div>
            <div class="qty">
                <button type="button" data-delta="-1">-</button>
                <strong>${qty}</strong>
                <button type="button" data-delta="1">+</button>
            </div>
            <button class="remove" type="button">×</button>
        `;

        row.querySelector('[data-delta="-1"]').addEventListener('click', () => addItem(id, -1));
        row.querySelector('[data-delta="1"]').addEventListener('click', () => addItem(id, 1));
        row.querySelector('.remove').addEventListener('click', () => {
            state.cart.delete(id);
            render();
        });
        els.cart.appendChild(row);
    }
}

function renderTotals() {
    const total = totals();
    els.cashTotal.textContent = formatMoney(total.charge);
    els.blackTotal.textContent = formatMoney(total.black);
    els.bankLabel.textContent = `PAY WITH BANK + VAT ${total.vatPercent}%(${formatMoney(total.vat)})`;
    els.useBank.disabled = !(state.store?.payment?.allowBank);
}

function render() {
    renderCategories();
    renderItems();
    renderCart();
    renderTotals();
    els.payBtn.disabled = state.pending || state.cart.size === 0;
}

function addItem(id, delta) {
    const item = state.items.find((entry) => entry.id === id);
    if (!item || state.pending) return;

    const current = state.cart.get(id) || 0;
    const max = Number(item.max) || 100;
    const next = Math.max(0, Math.min(max, current + delta));

    if (next === 0) state.cart.delete(id);
    else state.cart.set(id, next);

    render();
}

function openShop(payload) {
    state.open = true;
    state.pending = false;
    state.store = payload.store;
    state.items = payload.store.items || [];
    state.categories = payload.store.categories || [{ id: 'all', label: 'ALL' }];
    state.activeCategory = state.categories[0]?.id || 'all';
    state.imagePath = payload.imagePath || '';
    state.cart.clear();

    els.title.textContent = payload.store.title || 'ร้านค้า';
    els.subtitle.textContent = payload.store.subtitle || '';
    els.useBank.checked = false;
    els.shop.classList.remove('hidden');
    els.shop.setAttribute('aria-hidden', 'false');
    render();
}

function closeShop() {
    state.open = false;
    state.pending = false;
    state.cart.clear();
    els.shop.classList.add('hidden');
    els.shop.setAttribute('aria-hidden', 'true');
}

els.useBank.addEventListener('change', renderTotals);
els.cancelBtn.addEventListener('click', () => {
    closeShop();
    post('close');
});

els.payBtn.addEventListener('click', () => {
    if (state.pending || state.cart.size === 0) return;

    state.pending = true;
    render();
    post('pay', {
        useBank: els.useBank.checked,
        cart: Array.from(state.cart.entries()).map(([id, qty]) => ({ id, qty }))
    });
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && state.open) {
        closeShop();
        post('close');
    }
});

window.addEventListener('resize', updateShopScale);
updateShopScale();

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') openShop(data);
    if (data.action === 'hide') closeShop();
    if (data.action === 'purchaseResult') {
        state.pending = false;
        if (data.result?.ok) closeShop();
        else render();
    }
});

if (!isNui) {
    window.addEventListener('DOMContentLoaded', () => {
        document.body.classList.add('mock-mode');
        openShop({
            store: mockStore,
            imagePath: 'assets/items/'
        });

        addItem('bread', 10);
        addItem('pickaxe', 1);
    });
}
