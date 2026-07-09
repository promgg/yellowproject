// nui.js — RedM NUI bridge

const IS_FIVEM = window.invokeNative !== undefined;
const RESOURCE = 'lp_marketplace';

function nuiFetch(action, data = {}) {
    if (!IS_FIVEM) return Promise.resolve(null);
    return fetch(`https://${RESOURCE}/${action}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data),
    }).catch(() => null);
}

// ─── Lua → NUI ───────────────────────────────────────────────────────────────
const NUI = {
    close()                   { nuiFetch('closeUI'); },
    getListings(data)         { nuiFetch('getListings', data); },
    getMyListings()           { nuiFetch('getMyListings'); },
    getItemClaims()           { nuiFetch('getItemClaims'); },
    getInventory()            { nuiFetch('getInventory'); },
    listItem(data)            { nuiFetch('listItem', data); },
    buyItem(id, qty)          { nuiFetch('buyItem', { id, qty: qty || 1 }); },
    cancelListing(id)         { nuiFetch('cancelListing', { id }); },
    claimItem(id)             { nuiFetch('claimItem', { id }); },
};

// ─── Lua → NUI messages ──────────────────────────────────────────────────────
window.addEventListener('message', (e) => {
    const msg = e.data;
    if (!msg || !msg.action) return;
    switch (msg.action) {
        case 'open':
            onOpen(msg);
            break;
        case 'close':
            hideUI();
            break;
        case 'receiveListings':
            onReceiveListings(msg.data);
            break;
        case 'receiveMyListings':
            onReceiveMyListings(msg.listings);
            break;
        case 'receiveItemClaims':
            onReceiveItemClaims(msg.claims);
            break;
        case 'receiveInventory':
            onReceiveInventory(msg.inventory);
            break;
        case 'refreshBuy':
            if (state.tab === 'buy') NUI.getListings({ category: state.category, search: state.search, page: state.page });
            break;
        case 'refreshSell':
            // refresh เสมอถ้า open อยู่ (ไม่เช็ค tab เพราะอาจ switch tab ช้ากว่า server response)
            NUI.getMyListings();
            break;
        case 'refreshItem':
            if (state.tab === 'item') NUI.getItemClaims();
            break;
    }
});

// ─── Mock for browser dev ─────────────────────────────────────────────────────
if (!IS_FIVEM) {
    setTimeout(() => {
        window.dispatchEvent(new MessageEvent('message', { data: {
            action: 'open',
            theme: {
                accentBuy:'#60cd8e', accentSell:'#ff6b6b', accentItem:'#f0ca78',
                btnBuyBg:'rgba(96,205,142,0.14)', btnSellBg:'rgba(255,107,107,0.14)', btnItemBg:'rgba(240,202,120,0.14)',
                accent:'#937036',
            },
            categories: [
                { id:'general',  label:'ไอเทมทั่วไป', icon:'fa-box'      },
                { id:'food',     label:'อาหาร',        icon:'fa-utensils' },
                { id:'vehicle',  label:'ยานพาหนะ',     icon:'fa-car'      },
                { id:'material', label:'วัตถุดิบ',     icon:'fa-cubes'    },
            ],
            currencies: {
                money: { enabled:true, label:'เงินสด', color:'#60cd8e' },
                gold:  { enabled:true, label:'ทอง',    color:'#f0ca78' },
            },
            durations: [12, 24, 48],
            taxRate: 10,
        }}));
    }, 100);

    // Mock inventory — override NUI.getInventory โดยตรง (nuiFetch short-circuits ก่อนถึง window.fetch)
    NUI.getInventory = function() {
        setTimeout(() => {
            window.dispatchEvent(new MessageEvent('message', { data: {
                action: 'receiveInventory',
                inventory: [
                    { name:'meat_small',  label:'เนื้อเล็ก',  count:12, category:'food'      },
                    { name:'meat_large',  label:'เนื้อใหญ่',  count:6,  category:'food'      },
                    { name:'iron_ore',    label:'สินแร่เหล็ก', count:5,  category:'material'  },
                    { name:'gold_watch',  label:'นาฬิกาทอง',  count:1,  category:'general'   },
                ],
            }}));
        }, 200);
    };

    // Mock listings after open
    setTimeout(() => {
        window.dispatchEvent(new MessageEvent('message', { data: {
            action: 'receiveListings',
            data: {
                listings: [
                    { id:1, seller_name:'ทดสอบ', item_name:'gold_watch', item_label:'นาฬิกาทอง', category:'general',  quantity:1, price:1000, currency:'money', expires_at:'2026-08-25 13:32:00' },
                    { id:2, seller_name:'ผู้ขาย', item_name:'meat_large', item_label:'เนื้อใหญ่', category:'food',     quantity:5, price:50,   currency:'money', expires_at:'2026-08-26 09:00:00' },
                    { id:3, seller_name:'คาวบอย', item_name:'iron_ore',   item_label:'สินแร่เหล็ก', category:'material', quantity:2, price:80,   currency:'gold',  expires_at:'2026-08-24 23:00:00' },
                ],
                total: 3, page: 1,
            },
        }}));
    }, 300);
}
