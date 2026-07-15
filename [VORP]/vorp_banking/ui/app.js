(() => {
    'use strict';

    const resourceName = typeof window.GetParentResourceName === 'function'
        ? window.GetParentResourceName()
        : 'vorp_banking';

    const state = {
        visible: false,
        mode: null,
        currency: 'cash',
        submitting: false,
        bank: {},
        account: {},
        player: {},
        capabilities: {},
        transferBanks: [],
    };

    const el = {
        root: document.getElementById('bank-root'),
        title: document.getElementById('bank-title'),
        subtitle: document.getElementById('bank-subtitle'),
        accountId: document.getElementById('account-id'),
        bankMoney: document.getElementById('bank-money'),
        walletMoney: document.getElementById('wallet-money'),
        bankGold: document.getElementById('bank-gold'),
        goldSummary: document.getElementById('gold-summary'),
        lockerButton: document.getElementById('locker-button'),
        lockerCaption: document.getElementById('locker-caption'),
        upgradeButton: document.getElementById('upgrade-button'),
        upgradeCaption: document.getElementById('upgrade-caption'),
        transferButton: document.getElementById('transfer-button'),
        playerId: document.getElementById('player-id'),
        openingHours: document.getElementById('opening-hours'),
        modal: document.getElementById('modal'),
        modalForm: document.getElementById('modal-form'),
        modalClose: document.getElementById('modal-close'),
        modalKicker: document.getElementById('modal-kicker'),
        modalTitle: document.getElementById('modal-title'),
        modalDescription: document.getElementById('modal-description'),
        transactionFields: document.getElementById('transaction-fields'),
        upgradeFields: document.getElementById('upgrade-fields'),
        transferFields: document.getElementById('transfer-fields'),
        currencyTabs: document.getElementById('currency-tabs'),
        amountSymbol: document.getElementById('amount-symbol'),
        amountInput: document.getElementById('amount-input'),
        amountUnit: document.getElementById('amount-unit'),
        availableLabel: document.getElementById('available-label'),
        availableValue: document.getElementById('available-value'),
        currentSlots: document.getElementById('current-slots'),
        maxSlots: document.getElementById('max-slots'),
        slotPrice: document.getElementById('slot-price'),
        slotMeterFill: document.getElementById('slot-meter-fill'),
        slotCount: document.getElementById('slot-count'),
        slotMinus: document.getElementById('slot-minus'),
        slotPlus: document.getElementById('slot-plus'),
        upgradeTotal: document.getElementById('upgrade-total'),
        transferBank: document.getElementById('transfer-bank'),
        transferAmount: document.getElementById('transfer-amount'),
        transferNote: document.getElementById('transfer-note'),
        formError: document.getElementById('form-error'),
        confirmButton: document.getElementById('confirm-button'),
        toast: document.getElementById('toast'),
    };

    const numberValue = (value) => {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : 0;
    };

    const money = (value) => numberValue(value).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
    });

    const integer = (value) => Math.max(0, Math.floor(numberValue(value)));

    const cleanText = (value, fallback = '') => {
        if (value === undefined || value === null || value === '') return fallback;
        return String(value);
    };

    async function post(callback, payload = {}) {
        if (window.location.protocol === 'file:') {
            return { ok: true };
        }

        const response = await fetch(`https://${resourceName}/${callback}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload),
        });

        try {
            return await response.json();
        } catch (_) {
            return { ok: response.ok };
        }
    }

    function setText(node, value) {
        if (node && node.textContent !== String(value)) node.textContent = String(value);
    }

    function updateScale() {
        const scale = Math.min(1, window.innerWidth / 1920, window.innerHeight / 1080);
        el.root.style.setProperty('--ui-scale', String(Math.max(0.68, scale)));
    }

    function closeModal() {
        state.mode = null;
        state.submitting = false;
        el.modal.classList.add('is-hidden');
        el.formError.textContent = '';
        el.confirmButton.disabled = false;
    }

    function closeUi() {
        state.visible = false;
        closeModal();
        el.root.classList.add('is-hidden');
    }

    function currencyAvailable(direction = state.mode, currency = state.currency) {
        if (currency === 'gold') {
            return direction === 'deposit'
                ? numberValue(state.player.gold)
                : numberValue(state.account.gold);
        }

        return direction === 'deposit'
            ? numberValue(state.player.money)
            : numberValue(state.account.money);
    }

    function updateTransactionForm() {
        const isGold = state.currency === 'gold';
        const available = currencyAvailable();
        el.currencyTabs.querySelectorAll('button').forEach((button) => {
            button.classList.toggle('is-active', button.dataset.currency === state.currency);
        });
        setText(el.amountSymbol, isGold ? 'G' : '$');
        setText(el.amountUnit, isGold ? 'GOLD' : 'USD');
        setText(el.availableValue, `${isGold ? 'G ' : '$'}${money(available)}`);
        el.amountInput.max = String(available);
    }

    function showTransaction(direction) {
        state.mode = direction;
        state.currency = 'cash';
        el.transactionFields.classList.remove('is-hidden');
        el.upgradeFields.classList.add('is-hidden');
        el.transferFields.classList.add('is-hidden');
        el.currencyTabs.querySelector('[data-currency="gold"]').classList.toggle('is-hidden', !state.capabilities.gold);
        setText(el.modalKicker, direction === 'deposit' ? 'DEPOSIT' : 'WITHDRAW');
        setText(el.modalTitle, direction === 'deposit' ? 'ฝากเงินเข้าบัญชี' : 'ถอนเงินจากบัญชี');
        setText(el.modalDescription, direction === 'deposit' ? 'เลือกประเภทและจำนวนที่ต้องการฝาก' : 'เลือกประเภทและจำนวนที่ต้องการถอน');
        setText(el.availableLabel, direction === 'deposit' ? 'ยอดในกระเป๋าที่ใช้ได้' : 'ยอดในบัญชีที่ใช้ได้');
        setText(el.confirmButton, direction === 'deposit' ? 'ยืนยันการฝากเงิน' : 'ยืนยันการถอนเงิน');
        el.amountInput.value = '';
        el.formError.textContent = '';
        updateTransactionForm();
        el.modal.classList.remove('is-hidden');
        window.setTimeout(() => el.amountInput.focus(), 60);
    }

    function updateUpgradeTotal() {
        const count = Math.max(1, integer(el.slotCount.value));
        el.slotCount.value = String(count);
        setText(el.upgradeTotal, `$${money(count * numberValue(state.capabilities.costSlot))}`);
    }

    function showUpgrade() {
        state.mode = 'upgrade';
        const current = integer(state.account.invspace);
        const max = integer(state.capabilities.maxSlots);
        el.transactionFields.classList.add('is-hidden');
        el.upgradeFields.classList.remove('is-hidden');
        el.transferFields.classList.add('is-hidden');
        setText(el.modalKicker, 'SAFE BOX UPGRADE');
        setText(el.modalTitle, 'อัปเกรดล็อคเกอร์');
        setText(el.modalDescription, 'ซื้อพื้นที่เพิ่มและชำระด้วยเงินสดในกระเป๋า');
        setText(el.currentSlots, current);
        setText(el.maxSlots, max);
        setText(el.slotPrice, money(state.capabilities.costSlot));
        el.slotMeterFill.style.width = `${max > 0 ? Math.min(100, current / max * 100) : 0}%`;
        el.slotCount.max = String(Math.max(1, max - current));
        el.slotCount.value = '1';
        setText(el.confirmButton, 'ยืนยันการอัปเกรด');
        el.formError.textContent = '';
        updateUpgradeTotal();
        el.modal.classList.remove('is-hidden');
    }

    function showTransfer() {
        state.mode = 'transfer';
        el.transactionFields.classList.add('is-hidden');
        el.upgradeFields.classList.add('is-hidden');
        el.transferFields.classList.remove('is-hidden');
        setText(el.modalKicker, 'BRANCH TRANSFER');
        setText(el.modalTitle, 'โอนเงินระหว่างสาขา');
        setText(el.modalDescription, 'เลือกบัญชีต้นทางเพื่อโอนเข้าบัญชีสาขาปัจจุบัน');
        setText(el.confirmButton, 'ยืนยันการโอนเงิน');
        el.transferBank.innerHTML = '';
        state.transferBanks.forEach((bank) => {
            const option = document.createElement('option');
            option.value = bank.name;
            option.textContent = `${bank.label || bank.name} · $${money(bank.money)}`;
            el.transferBank.appendChild(option);
        });
        el.transferAmount.value = '';
        el.formError.textContent = '';
        el.modal.classList.remove('is-hidden');
        window.setTimeout(() => el.transferAmount.focus(), 60);
    }

    function renderOpen(data) {
        state.visible = true;
        state.bank = data.bank || {};
        state.account = data.account || {};
        state.player = data.player || {};
        state.capabilities = data.capabilities || {};
        state.transferBanks = Array.isArray(data.transferBanks) ? data.transferBanks : [];

        setText(el.title, cleanText(state.bank.displayName, state.bank.name || 'ธนาคาร'));
        setText(el.subtitle, cleanText(state.bank.subtitle, `${state.bank.name || 'BANK'} SAVINGS & TRUST`).toUpperCase());
        setText(el.accountId, cleanText(state.account.accountId, '--'));
        setText(el.bankMoney, money(state.account.money));
        setText(el.walletMoney, money(state.player.money));
        setText(el.bankGold, money(state.account.gold));
        setText(el.playerId, `ID : ${cleanText(state.player.id, '--')}`);
        setText(el.openingHours, cleanText(state.bank.hours, 'เปิดทำการ'));
        setText(el.lockerCaption, `พื้นที่ปัจจุบัน ${integer(state.account.invspace)} / ${integer(state.capabilities.maxSlots)} ช่อง`);
        setText(el.upgradeCaption, `เพิ่มช่องละ $${money(state.capabilities.costSlot)} · สูงสุด ${integer(state.capabilities.maxSlots)}`);

        el.goldSummary.classList.toggle('is-hidden', !state.capabilities.gold);
        el.lockerButton.disabled = !state.capabilities.locker;
        el.upgradeButton.disabled = !state.capabilities.upgrade ||
            integer(state.account.invspace) >= integer(state.capabilities.maxSlots);
        el.transferButton.classList.toggle('is-hidden', !state.capabilities.transfer || state.transferBanks.length === 0);

        closeModal();
        el.root.classList.remove('is-hidden');
        updateScale();
    }

    function showError(message) {
        el.formError.textContent = message;
    }

    let toastTimer = 0;
    function showToast(message) {
        window.clearTimeout(toastTimer);
        setText(el.toast, message);
        el.toast.classList.remove('is-hidden');
        toastTimer = window.setTimeout(() => el.toast.classList.add('is-hidden'), 2800);
    }

    async function submitForm(event) {
        event.preventDefault();
        if (state.submitting) return;

        let callback = '';
        let payload = {};

        if (state.mode === 'deposit' || state.mode === 'withdraw') {
            const amount = numberValue(el.amountInput.value);
            const available = currencyAvailable();
            if (amount <= 0) return showError('กรุณาระบุจำนวนที่มากกว่า 0');
            if (amount > available) return showError('ยอดเงินไม่เพียงพอสำหรับรายการนี้');
            callback = 'transaction';
            payload = { direction: state.mode, currency: state.currency, amount };
        } else if (state.mode === 'upgrade') {
            const slots = integer(el.slotCount.value);
            const current = integer(state.account.invspace);
            const max = integer(state.capabilities.maxSlots);
            const cost = slots * numberValue(state.capabilities.costSlot);
            if (slots < 1) return showError('กรุณาระบุจำนวนช่องอย่างน้อย 1 ช่อง');
            if (current + slots > max) return showError('จำนวนช่องเกินขีดจำกัดของล็อคเกอร์');
            if (cost > numberValue(state.player.money)) return showError('เงินสดไม่เพียงพอสำหรับการอัปเกรด');
            callback = 'upgradeLocker';
            payload = { slots };
        } else if (state.mode === 'transfer') {
            const amount = numberValue(el.transferAmount.value);
            const fromBank = el.transferBank.value;
            const source = state.transferBanks.find((bank) => bank.name === fromBank);
            if (!fromBank || !source) return showError('ไม่พบบัญชีต้นทาง');
            if (amount <= 0) return showError('กรุณาระบุจำนวนที่มากกว่า 0');
            if (amount > numberValue(source.money)) return showError('ยอดบัญชีต้นทางไม่เพียงพอ');
            callback = 'transfer';
            payload = { amount, fromBank };
        } else {
            return;
        }

        state.submitting = true;
        el.confirmButton.disabled = true;
        el.formError.textContent = '';

        try {
            const result = await post(callback, payload);
            if (result && result.ok === false) {
                state.submitting = false;
                el.confirmButton.disabled = false;
                return showError(result.error || 'ไม่สามารถทำรายการได้');
            }
        } catch (_) {
            state.submitting = false;
            el.confirmButton.disabled = false;
            showError('การเชื่อมต่อขัดข้อง กรุณาลองใหม่');
        }
    }

    document.querySelectorAll('.action-card').forEach((button) => {
        button.addEventListener('click', async () => {
            if (button.disabled) return;
            const action = button.dataset.action;
            if (action === 'deposit' || action === 'withdraw') return showTransaction(action);
            if (action === 'upgrade') return showUpgrade();
            if (action === 'locker') {
                if (integer(state.account.invspace) <= 0) {
                    if (state.capabilities.upgrade) return showUpgrade();
                    return showToast('ล็อคเกอร์ยังไม่มีพื้นที่ใช้งาน');
                }
                button.disabled = true;
                try {
                    const result = await post('openLocker');
                    if (result && result.ok === false) showToast(result.error || 'ไม่สามารถเปิดล็อคเกอร์ได้');
                } catch (_) {
                    showToast('การเชื่อมต่อขัดข้อง กรุณาลองใหม่');
                } finally {
                    button.disabled = false;
                }
            }
        });
    });

    el.transferButton.addEventListener('click', showTransfer);
    el.modalClose.addEventListener('click', closeModal);
    el.modal.addEventListener('mousedown', (event) => { if (event.target === el.modal) closeModal(); });
    el.modalForm.addEventListener('submit', submitForm);

    el.currencyTabs.addEventListener('click', (event) => {
        const button = event.target.closest('button[data-currency]');
        if (!button) return;
        state.currency = button.dataset.currency;
        el.amountInput.value = '';
        updateTransactionForm();
    });

    document.querySelector('.quick-amounts').addEventListener('click', (event) => {
        const button = event.target.closest('button[data-amount]');
        if (!button) return;
        el.amountInput.value = button.dataset.amount === 'all'
            ? String(currencyAvailable())
            : button.dataset.amount;
    });

    el.slotMinus.addEventListener('click', () => {
        el.slotCount.value = String(Math.max(1, integer(el.slotCount.value) - 1));
        updateUpgradeTotal();
    });
    el.slotPlus.addEventListener('click', () => {
        const limit = Math.max(1, integer(el.slotCount.max));
        el.slotCount.value = String(Math.min(limit, Math.max(1, integer(el.slotCount.value) + 1)));
        updateUpgradeTotal();
    });
    el.slotCount.addEventListener('input', updateUpgradeTotal);

    window.addEventListener('keydown', async (event) => {
        if (event.key !== 'Escape' || !state.visible) return;
        if (!el.modal.classList.contains('is-hidden')) return closeModal();
        await post('close');
    });
    window.addEventListener('resize', updateScale);
    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || typeof data !== 'object') return;
        if (data.action === 'open') renderOpen(data);
        if (data.action === 'close') closeUi();
    });

    closeUi();

    if (window.location.protocol === 'file:') {
        const previewView = new URLSearchParams(window.location.search).get('view');
        window.setTimeout(() => {
            renderOpen({
            bank: { name: 'Valentine', displayName: 'ธนาคารวาเลนไทน์', subtitle: 'VALENTINE SAVINGS & TRUST', hours: 'เปิดทำการ 07:00–22:00' },
            account: { accountId: 'VL-1849-999', money: 12450.75, gold: 12, invspace: 24 },
            player: { id: 999, money: 1280, gold: 4 },
            capabilities: { gold: true, locker: true, upgrade: true, transfer: true, costSlot: 250, maxSlots: 100 },
            transferBanks: [{ name: 'SaintDenis', label: 'Saint Denis', money: 3400 }],
            });

            if (previewView === 'deposit' || previewView === 'withdraw') showTransaction(previewView);
            if (previewView === 'upgrade') showUpgrade();
            if (previewView === 'transfer') showTransfer();
        }, 80);
    }
})();
