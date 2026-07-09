"use strict";

const state = {
    visible: false,
    type: "main",
    inventoryItems: [],
    secondaryItems: [],
    fastSlots: Array.from({ length: 6 }, (_, index) => ({ slot: index + 1, item: null })),
    selectedItem: null,
    selectedSlot: null,
    selectedInventory: "main",
    weight: 0,
    maxWeight: 0,
    money: 0,
    gold: 0,
    rol: 0,
    playerId: 0,
    searchText: "",
    context: null,
    language: {},
    config: {
        DoubleClickToUse: true,
        WeightMeasure: "KG",
        MaxItemTransferAmount: 200,
    },
    actionConfig: {},
    imageCache: {},
    secondary: {
        visible: false,
        title: "",
        capacity: null,
        weight: null,
        ids: {},
    },
    pendingGive: null,
    pendingQuantity: null,
};

const els = {};
const secondaryCallbacks = {
    custom: { move: "MoveToCustom", take: "TakeFromCustom", idKey: "id" },
    player: { move: "MoveToPlayer", take: "TakeFromPlayer", idKey: "player" },
    store: { move: "MoveToStore", take: "TakeFromStore", idKey: "store" },
    horse: { move: "MoveToHorse", take: "TakeFromHorse", idKey: "horse" },
    steal: { move: "MoveTosteal", take: "TakeFromsteal", idKey: "steal" },
    cart: { move: "MoveToCart", take: "TakeFromCart", idKey: "wagon" },
    house: { move: "MoveToHouse", take: "TakeFromHouse", idKey: "house" },
    bank: { move: "MoveToBank", take: "TakeFromBank", idKey: "bank" },
    hideout: { move: "MoveToHideout", take: "TakeFromHideout", idKey: "hideout" },
    clan: { move: "MoveToClan", take: "TakeFromClan", idKey: "clan" },
    container: { move: "MoveToContainer", take: "TakeFromContainer", idKey: "Container" },
};

function cacheElements() {
    els.root = document.getElementById("inventory-root");
    els.fastSlots = document.getElementById("fast-slots");
    els.inventoryGrid = document.getElementById("inventory-grid");
    els.inventoryEmpty = document.getElementById("inventory-empty");
    els.weightFill = document.getElementById("weight-fill");
    els.weightText = document.getElementById("weight-text");
    els.moneyValue = document.getElementById("money-value");
    els.playerId = document.getElementById("player-id");
    els.selectedPanel = document.getElementById("selected-panel");
    els.selectedName = document.getElementById("selected-name");
    els.selectedMeta = document.getElementById("selected-meta");
    els.actionStrip = document.getElementById("action-strip");
    els.contextMenu = document.getElementById("context-menu");
    els.secondaryPanel = document.getElementById("secondary-panel");
    els.secondaryTitle = document.getElementById("secondary-title");
    els.secondaryCapacity = document.getElementById("secondary-capacity");
    els.secondaryGrid = document.getElementById("secondary-grid");
    els.secondaryEmpty = document.getElementById("secondary-empty");
    els.playerModal = document.getElementById("player-modal");
    els.playerModalTitle = document.getElementById("player-modal-title");
    els.playerModalClose = document.getElementById("player-modal-close");
    els.playerList = document.getElementById("player-list");
    els.quantityModal = document.getElementById("quantity-modal");
    els.quantityForm = document.getElementById("quantity-form");
    els.quantityClose = document.getElementById("quantity-close");
    els.quantityTitle = document.getElementById("quantity-title");
    els.quantityInput = document.getElementById("quantity-input");
    els.transaction = document.getElementById("transaction-loader");
    els.transactionText = document.getElementById("transaction-text");
}

function setVisible(visible) {
    state.visible = Boolean(visible);
    els.root.classList.toggle("is-hidden", !state.visible);
    if (!state.visible) {
        closeContextMenu();
        closePlayerModal();
        closeQuantityModal();
        state.selectedItem = null;
        state.selectedSlot = null;
        renderSelectedItem();
    }
}

function renderInventory() {
    const items = getFilteredItems(state.inventoryItems);
    els.inventoryGrid.innerHTML = "";
    els.inventoryEmpty.classList.toggle("is-hidden", items.length > 0);

    items.forEach((item, index) => {
        els.inventoryGrid.appendChild(createItemCard(item, index, "main"));
    });
}

function renderSecondaryInventory() {
    const items = Array.isArray(state.secondaryItems) ? state.secondaryItems : [];
    els.secondaryPanel.classList.toggle("is-hidden", !state.secondary.visible);
    els.secondaryTitle.textContent = state.secondary.title || "Storage";
    els.secondaryCapacity.textContent = formatSecondaryCapacity();
    els.secondaryGrid.innerHTML = "";
    els.secondaryEmpty.classList.toggle("is-hidden", items.length > 0 || !state.secondary.visible);

    items.forEach((item, index) => {
        els.secondaryGrid.appendChild(createItemCard(item, index, "second"));
    });
}

function renderFastSlots() {
    const slots = normalizeFastSlots();
    els.fastSlots.innerHTML = "";

    slots.forEach((slot) => {
        const button = document.createElement("button");
        const item = slot.item;
        button.type = "button";
        button.className = "fast-slot";
        button.dataset.slot = String(slot.slot);
        button.classList.toggle("is-filled", Boolean(item));
        button.classList.toggle("is-selected", state.selectedSlot === slot.slot);
        button.innerHTML = `<span class="fast-slot-number">${slot.slot}</span>`;

        if (item) {
            const normalized = normalizeItem(item, slot.slot);
            button.appendChild(createImage(normalized, normalized.label));
            button.insertAdjacentHTML("beforeend", `<span class="fast-slot-amount">${formatAmount(normalized, true)}</span>`);
            button.insertAdjacentHTML("beforeend", `<span class="fast-slot-label">${escapeHtml(normalized.label)}</span>`);
        }

        button.addEventListener("click", () => {
            state.selectedSlot = slot.slot;
            if (item) {
                selectItem(item, "main", null);
            }
            renderFastSlots();
        });

        button.addEventListener("contextmenu", (event) => {
            event.preventDefault();
            state.selectedSlot = slot.slot;
            if (item) {
                selectItem(item, "main", event);
            } else {
                renderFastSlots();
            }
        });

        els.fastSlots.appendChild(button);
    });
}

function renderWeight() {
    const weight = numberOrZero(state.weight);
    const maxWeight = numberOrZero(state.maxWeight);
    const unit = String(state.config.WeightMeasure || "KG").toUpperCase();
    const pct = maxWeight > 0 ? Math.max(0, Math.min(100, (weight / maxWeight) * 100)) : 0;

    els.weightFill.style.width = `${pct}%`;
    els.weightFill.classList.toggle("is-over", maxWeight > 0 && weight > maxWeight);
    els.weightText.textContent = `${formatNumber(weight)} / ${formatNumber(maxWeight)} ${unit}`;
}

function renderMoney() {
    els.moneyValue.textContent = formatCurrency(state.money);
}

function renderPlayerId() {
    els.playerId.textContent = `ID : ${state.playerId || 0}`;
}

function renderSelectedItem() {
    const item = state.selectedItem ? normalizeItem(state.selectedItem) : null;
    els.selectedPanel.classList.toggle("is-hidden", !item);

    if (!item) {
        els.selectedName.textContent = "";
        els.selectedMeta.textContent = "";
        els.actionStrip.innerHTML = "";
        renderActions();
        return;
    }

    els.selectedName.textContent = item.label;
    els.selectedMeta.textContent = buildSelectedMeta(item);
    renderInventory();
    renderSecondaryInventory();
    renderFastSlots();
    renderActions();
}

function renderActions() {
    els.actionStrip.innerHTML = "";
    if (!state.selectedItem) return;

    const item = normalizeItem(state.selectedItem);
    const actions = [];

    if (state.selectedInventory === "main") {
        if (item.type === "item_weapon") {
            actions.push({ label: item.used || item.used2 ? "Unequip" : "Use", handler: () => (item.used || item.used2 ? unequipSelected(item) : useSelected(item)) });
        } else {
            actions.push({ label: "Use", handler: () => useSelected(item) });
        }
        actions.push({ label: "Give", handler: () => beginGive(item) });
        actions.push({ label: "Drop", handler: () => beginDrop(item) });
        if (state.secondary.visible) {
            actions.push({ label: "Move", handler: () => beginMoveTake("move", item) });
        }
        actions.push({ label: "Slot", handler: () => addSelectedToFastSlot(item) });
        if (selectedItemIsInSelectedSlot(item)) {
            actions.push({ label: "Clear", handler: () => removeFastSlot(state.selectedSlot) });
        }
    } else {
        actions.push({ label: "Take", handler: () => beginMoveTake("take", item) });
    }

    actions.forEach((action) => {
        const button = document.createElement("button");
        button.type = "button";
        button.textContent = action.label;
        button.addEventListener("click", action.handler);
        els.actionStrip.appendChild(button);
    });
}

function postNui(callbackName, payload = {}) {
    const body = {
        ...payload,
        hsn: encodeHash(generateId()),
    };

    return fetch(`https://${getResourceName()}/${callbackName}`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(body),
    }).catch(() => undefined);
}

function requestActionsConfig() {
    fetch(`https://${getResourceName()}/getActionsConfig`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify({}),
    })
        .then((response) => response.json())
        .then((config) => {
            state.actionConfig = config && typeof config === "object" ? config : {};
        })
        .catch(() => {
            state.actionConfig = {};
        });
}

function safeGetItemImage(item) {
    const normalized = normalizeItem(item);
    const metadataImage = normalized.metadata && typeof normalized.metadata.image === "string" ? normalized.metadata.image : "";
    const candidate = metadataImage || normalized.image || normalized.name || "placeholder";
    const cleaned = cleanImageName(candidate);

    if (state.imageCache[cleaned]) return state.imageCache[cleaned];
    if (/^(https?:|nui:\/\/|data:)/i.test(candidate)) return candidate;
    if (candidate.includes("/") && /\.(png|webp|jpg|jpeg)$/i.test(candidate)) return candidate;

    return `img/items/${cleaned}.png`;
}

function createItemCard(item, index, inventoryName) {
    const normalized = normalizeItem(item, index);
    const button = document.createElement("button");
    button.type = "button";
    button.className = "item-card";
    button.dataset.inventory = inventoryName;
    button.dataset.itemId = String(normalized.id ?? normalized.name ?? index);
    button.classList.toggle("is-selected", isSelected(normalized, inventoryName));

    if (normalized.used || normalized.used2) {
        button.insertAdjacentHTML("beforeend", `<span class="equipped-dot"></span>`);
    }

    const amount = formatAmount(normalized, false);
    if (amount) {
        button.insertAdjacentHTML("beforeend", `<span class="item-amount">${escapeHtml(amount)}</span>`);
    }

    button.appendChild(createImage(normalized, normalized.label));
    button.insertAdjacentHTML("beforeend", `<span class="item-label">${escapeHtml(normalized.label)}</span>`);

    button.addEventListener("click", () => selectItem(item, inventoryName, null));
    button.addEventListener("dblclick", () => {
        selectItem(item, inventoryName, null);
        if (inventoryName === "main" && state.config.DoubleClickToUse !== false) {
            useSelected(normalized);
        }
    });
    button.addEventListener("contextmenu", (event) => {
        event.preventDefault();
        selectItem(item, inventoryName, event);
    });

    return button;
}

function createImage(item, alt) {
    const image = document.createElement("img");
    image.src = safeGetItemImage(item);
    image.alt = alt || "";
    image.draggable = false;
    image.onerror = () => {
        image.onerror = null;
        image.src = "img/items/placeholder.png";
    };
    return image;
}

function selectItem(item, inventoryName, event) {
    state.selectedItem = item;
    state.selectedInventory = inventoryName || "main";
    closeContextMenu();
    renderSelectedItem();

    if (event) {
        openContextMenu(event.clientX, event.clientY);
    }
}

function openContextMenu(x, y) {
    if (!state.selectedItem) return;
    els.contextMenu.innerHTML = "";

    const item = normalizeItem(state.selectedItem);
    const entries = [];

    if (state.selectedInventory === "main") {
        entries.push({ label: item.type === "item_weapon" && (item.used || item.used2) ? "Unequip" : "Use", handler: () => item.type === "item_weapon" && (item.used || item.used2) ? unequipSelected(item) : useSelected(item) });
        entries.push({ label: "Give", handler: () => beginGive(item) });
        entries.push({ label: "Drop", handler: () => beginDrop(item) });
        if (state.secondary.visible) entries.push({ label: "Move", handler: () => beginMoveTake("move", item) });
        entries.push({ label: "Fast slot", handler: () => addSelectedToFastSlot(item) });
        if (selectedItemIsInSelectedSlot(item)) entries.push({ label: "Clear slot", handler: () => removeFastSlot(state.selectedSlot) });
        getContextActions(item).forEach((action) => {
            entries.push({ label: action.label, handler: () => runContextAction(action.data) });
        });
    } else {
        entries.push({ label: "Take", handler: () => beginMoveTake("take", item) });
    }

    entries.forEach((entry) => {
        const button = document.createElement("button");
        button.type = "button";
        button.textContent = entry.label;
        button.addEventListener("click", () => {
            closeContextMenu();
            entry.handler();
        });
        els.contextMenu.appendChild(button);
    });

    els.contextMenu.style.left = `${Math.min(x, window.innerWidth - 150)}px`;
    els.contextMenu.style.top = `${Math.min(y, window.innerHeight - 180)}px`;
    els.contextMenu.classList.remove("is-hidden");
}

function closeContextMenu() {
    els.contextMenu.classList.add("is-hidden");
}

function useSelected(item) {
    postNui("UseItem", item);
}

function unequipSelected(item) {
    postNui("UnequipWeapon", {
        item: item.name,
        id: item.id,
        used: item.used,
        used2: item.used2,
    });
}

function beginGive(item) {
    const normalized = normalizeItem(item);
    if (normalized.type === "item_weapon" || normalized.count <= 1) {
        requestNearPlayers(normalized, 1);
        return;
    }

    openQuantityModal("Give amount", normalized.count, (qty) => {
        requestNearPlayers(normalized, qty);
    });
}

function requestNearPlayers(item, qty) {
    state.pendingGive = toTransferPayload(item, qty);
    postNui("GetNearPlayers", state.pendingGive);
}

function beginDrop(item) {
    const normalized = normalizeItem(item);
    if (normalized.type === "item_weapon" || normalized.count <= 1) {
        dropSelected(normalized, 1);
        return;
    }

    openQuantityModal("Drop amount", normalized.count, (qty) => dropSelected(normalized, qty));
}

function dropSelected(item, qty) {
    const payload = toTransferPayload(item, qty);
    postNui("DropItem", {
        item: payload.item,
        id: payload.id,
        type: payload.type,
        number: payload.count,
        hash: payload.hash,
        metadata: payload.metadata,
        degradation: payload.degradation,
    });
}

function beginMoveTake(direction, item) {
    const normalized = normalizeItem(item);
    const max = normalized.type === "item_weapon" ? 1 : normalized.count;
    if (max <= 1) {
        moveTakeSelected(direction, normalized, 1);
        return;
    }

    openQuantityModal(direction === "move" ? "Move amount" : "Take amount", max, (qty) => {
        moveTakeSelected(direction, normalized, qty);
    });
}

function moveTakeSelected(direction, item, qty) {
    const context = getSecondaryContext();
    if (!context) return;

    const callback = direction === "take" ? context.take : context.move;
    const idValue = getSecondaryId(context.idKey);
    const payload = {
        item,
        type: item.type,
        number: qty,
        [context.idKey]: idValue,
        info: state.secondary.ids.info,
    };

    if (state.type === "store") {
        payload.store = state.secondary.ids.StoreId ?? state.secondary.ids.store ?? idValue;
        payload.geninfo = state.secondary.ids.geninfo;
        if (item.price) payload.price = item.price;
    }

    postNui(callback, payload);
}

function addSelectedToFastSlot(item) {
    const normalized = normalizeItem(item);
    const slot = state.selectedSlot || firstAvailableFastSlot();

    if (!slot) return;

    state.fastSlots = state.fastSlots.map((entry) => entry.slot === slot ? { slot, item: normalized } : entry);
    state.selectedSlot = slot;
    renderFastSlots();
    postNui("AddItemToFastSlot", {
        slot,
        item: normalized,
        id: normalized.id,
        type: normalized.type,
        name: normalized.name,
    });
}

function removeFastSlot(slot) {
    state.fastSlots = state.fastSlots.map((entry) => entry.slot === slot ? { slot, item: null } : entry);
    renderFastSlots();
    postNui("RemoveItemFromFastSlot", { slot });
}

function showPlayerModal(players, sourcePayload) {
    const list = Array.isArray(players) ? players : [];
    state.pendingGive = sourcePayload || state.pendingGive;
    els.playerList.innerHTML = "";
    els.playerModalTitle.textContent = state.language.toplayerpromptitle || "Select player";

    if (list.length === 0) {
        els.playerList.innerHTML = `<p class="empty-inline">No players nearby</p>`;
    } else {
        list.forEach((player) => {
            const button = document.createElement("button");
            button.type = "button";
            button.textContent = String(player.label ?? player.player ?? "Player");
            button.addEventListener("click", () => {
                postNui("GiveItem", {
                    player: player.player,
                    data: state.pendingGive,
                });
                closePlayerModal();
            });
            els.playerList.appendChild(button);
        });
    }

    els.playerModal.classList.remove("is-hidden");
}

function closePlayerModal() {
    els.playerModal.classList.add("is-hidden");
    els.playerList.innerHTML = "";
}

function openQuantityModal(title, max, onSubmit) {
    const cappedMax = Math.max(1, Math.min(numberOrZero(max) || 1, numberOrZero(state.config.MaxItemTransferAmount) || numberOrZero(max) || 1));
    state.pendingQuantity = onSubmit;
    els.quantityTitle.textContent = title;
    els.quantityInput.max = String(cappedMax);
    els.quantityInput.value = "1";
    els.quantityModal.classList.remove("is-hidden");
    setTimeout(() => els.quantityInput.focus(), 0);
}

function closeQuantityModal() {
    els.quantityModal.classList.add("is-hidden");
    state.pendingQuantity = null;
}

function submitQuantity(event) {
    event.preventDefault();
    const value = Math.floor(numberOrZero(els.quantityInput.value));
    const max = Math.floor(numberOrZero(els.quantityInput.max));

    if (value <= 0 || (max > 0 && value > max)) {
        postNui("TransferLimitExceeded", { max });
        return;
    }

    const callback = state.pendingQuantity;
    closeQuantityModal();
    if (callback) callback(value);
}

function handleMessage(event) {
    const data = event.data || {};

    switch (data.action) {
        case "display":
            handleDisplay(data);
            break;
        case "hide":
            setVisible(false);
            break;
        case "setItems":
            state.inventoryItems = normalizeList(data.itemList || data.items || []);
            if (data.timenow !== undefined) state.timeNow = data.timenow;
            renderInventory();
            renderFastSlots();
            break;
        case "setSecondInventoryItems":
            state.secondaryItems = normalizeList(data.itemList || data.items || []);
            state.secondary.ids.info = data.info;
            renderSecondaryInventory();
            break;
        case "changecheck":
            state.weight = numberOrZero(data.check ?? data.weight ?? data.current);
            state.maxWeight = numberOrZero(data.info ?? data.maxWeight ?? data.capacity);
            renderWeight();
            break;
        case "updateStatusHud":
            state.money = data.money ?? state.money;
            state.gold = data.gold ?? state.gold;
            state.rol = data.rol ?? state.rol;
            state.playerId = data.id ?? data.playerId ?? state.playerId;
            renderMoney();
            renderPlayerId();
            break;
        case "nearPlayers":
            showPlayerModal(data.players, buildPendingGiveFromNearPlayers(data));
            break;
        case "cacheImages":
            cacheImages(data.info);
            renderInventory();
            renderSecondaryInventory();
            renderFastSlots();
            break;
        case "initiate":
            state.language = data.language || {};
            state.config = { ...state.config, ...(data.config || {}) };
            renderWeight();
            break;
        case "transaction":
            renderTransaction(data);
            break;
        case "reclabels":
            state.ammoLabels = data.labels || {};
            break;
        case "updateammo":
            state.ammo = data.ammo || {};
            break;
        case "setFastSlots":
        case "fastSlots":
        case "updateFastSlots":
            updateFastSlots(data.slots || data.fastSlots || data.items || []);
            break;
        default:
            break;
    }
}

function handleDisplay(data) {
    state.type = normalizeType(data.type || "main");
    setVisible(true);

    if (state.type === "main") {
        state.secondary.visible = false;
    } else {
        state.secondary.visible = true;
        state.secondary.title = data.title || data.name || state.type;
        state.secondary.capacity = data.capacity ?? null;
        state.secondary.weight = data.weight ?? null;
        state.secondary.ids = {
            ...state.secondary.ids,
            id: data.id,
            StoreId: data.StoreId,
            store: data.StoreId,
            horse: data.horseid,
            steal: data.stealId,
            wagon: data.wagonid,
            house: data.houseId,
            bank: data.bankId,
            hideout: data.hideoutId,
            clan: data.clanid,
            Container: data.Containerid,
            geninfo: data.geninfo,
        };
    }

    renderSecondaryInventory();
}

function renderTransaction(data) {
    const started = data.type === "started";
    els.transaction.classList.toggle("is-hidden", !started);
    els.transactionText.textContent = data.text || "Loading";
}

function cacheImages(info) {
    if (!info) return;

    const values = Array.isArray(info) ? info : Object.values(info);
    values.forEach((name) => {
        if (!name) return;
        const clean = cleanImageName(String(name));
        state.imageCache[clean] = `img/items/${clean}.png`;
    });
}

function updateFastSlots(slots) {
    const next = Array.from({ length: 6 }, (_, index) => ({ slot: index + 1, item: null }));

    if (Array.isArray(slots)) {
        slots.forEach((entry, index) => {
            const slotNumber = numberOrZero(entry.slot ?? entry.key ?? entry.index ?? index + 1);
            if (slotNumber >= 1 && slotNumber <= 6) {
                next[slotNumber - 1] = { slot: slotNumber, item: entry.item || entry };
            }
        });
    } else if (typeof slots === "object") {
        Object.entries(slots).forEach(([slot, item]) => {
            const slotNumber = numberOrZero(slot);
            if (slotNumber >= 1 && slotNumber <= 6) {
                next[slotNumber - 1] = { slot: slotNumber, item };
            }
        });
    }

    state.fastSlots = next;
    renderFastSlots();
}

function normalizeItem(item, fallbackId = 0) {
    const source = item && typeof item === "object" ? item : {};
    const metadata = source.metadata && typeof source.metadata === "object" ? source.metadata : {};
    const label = source.custom_label || metadata.label || source.label || source.name || "Unknown";
    const name = source.name || source.item || label;
    const count = numberOrZero(source.count ?? source.amount ?? source.quantity ?? 1);
    const limit = source.limit ?? source.max ?? source.maxStack ?? null;

    return {
        ...source,
        id: source.id ?? source.itemId ?? source.key ?? fallbackId,
        name,
        item: source.item || name,
        label,
        count,
        limit,
        metadata,
        type: source.type || "item_standard",
        image: source.image || metadata.image || name,
        degradation: source.degradation,
        weight: source.weight,
        hash: source.hash,
        used: Boolean(source.used),
        used2: Boolean(source.used2),
    };
}

function normalizeList(list) {
    if (Array.isArray(list)) return list.filter(Boolean);
    if (typeof list === "object" && list !== null) return Object.values(list).filter(Boolean);
    return [];
}

function normalizeFastSlots() {
    const slots = Array.isArray(state.fastSlots) ? state.fastSlots : [];
    const normalized = Array.from({ length: 6 }, (_, index) => ({ slot: index + 1, item: null }));

    slots.forEach((entry, index) => {
        const slot = numberOrZero(entry.slot ?? index + 1);
        if (slot >= 1 && slot <= 6) normalized[slot - 1] = { slot, item: entry.item || null };
    });

    return normalized;
}

function getFilteredItems(items) {
    const list = normalizeList(items);
    const query = String(state.searchText || "").trim().toLowerCase();
    if (!query) return list;

    return list.filter((item) => {
        const normalized = normalizeItem(item);
        return normalized.name.toLowerCase().includes(query) || normalized.label.toLowerCase().includes(query);
    });
}

function formatAmount(item, fastSlot) {
    if (item.type === "item_weapon") return item.count > 0 && !fastSlot ? String(item.count) : "";
    const count = numberOrZero(item.count);
    const limit = numberOrZero(item.limit);
    if (limit > 0) return `${count}/${limit}`;
    return count > 1 || fastSlot ? String(count) : "";
}

function formatNumber(value) {
    const number = numberOrZero(value);
    return Number.isInteger(number) ? String(number) : number.toFixed(1);
}

function formatCurrency(value) {
    const number = numberOrZero(value);
    return Math.round(number).toLocaleString("en-US").replace(/,/g, "");
}

function formatSecondaryCapacity() {
    if (state.secondary.capacity === null && state.secondary.weight === null) return "";
    const weight = state.secondary.weight !== null ? formatNumber(state.secondary.weight) : "0";
    const capacity = state.secondary.capacity !== null ? formatNumber(state.secondary.capacity) : "";
    return capacity ? `${weight}/${capacity}` : weight;
}

function buildSelectedMeta(item) {
    const pieces = [];
    if (item.type === "item_weapon" && item.serial_number) pieces.push(`Serial ${item.serial_number}`);
    if (item.weight !== undefined) pieces.push(`${formatNumber(item.weight)} ${String(state.config.WeightMeasure || "KG").toUpperCase()}`);
    if (item.metadata && item.metadata.description) pieces.push(stripHtml(String(item.metadata.description)));
    if (item.desc) pieces.push(stripHtml(String(item.desc)));
    return pieces.filter(Boolean).join(" / ");
}

function toTransferPayload(item, qty) {
    return {
        ...item,
        item: item.name,
        count: qty,
        number: qty,
        type: item.type,
        id: item.id,
        hash: item.hash,
        metadata: item.metadata,
        degradation: item.degradation,
        what: state.selectedInventory,
    };
}

function buildPendingGiveFromNearPlayers(data) {
    return {
        item: data.item,
        hash: data.hash,
        count: data.count,
        id: data.id,
        type: data.type,
        what: data.what,
    };
}

function getContextActions(item) {
    const context = item.metadata?.context || item.context;
    const actions = Array.isArray(context) ? context : (context && typeof context === "object" ? Object.values(context) : []);

    return actions
        .filter((action) => action && typeof action === "object")
        .map((action) => ({
            label: String(action.text || action.label || action.title || action.name || "Action"),
            data: action,
        }));
}

function runContextAction(action) {
    postNui("ContextMenu", action);
}

function getSecondaryContext() {
    return secondaryCallbacks[state.type] || secondaryCallbacks[normalizeType(state.type)];
}

function getSecondaryId(idKey) {
    return state.secondary.ids[idKey] ?? state.secondary.ids.id ?? 0;
}

function firstAvailableFastSlot() {
    const entry = normalizeFastSlots().find((slot) => !slot.item);
    return entry ? entry.slot : 1;
}

function selectedItemIsInSelectedSlot(item) {
    if (!state.selectedSlot) return false;
    const slot = normalizeFastSlots().find((entry) => entry.slot === state.selectedSlot);
    if (!slot || !slot.item) return false;
    const slotItem = normalizeItem(slot.item);
    return slotItem.id === item.id && slotItem.name === item.name && slotItem.type === item.type;
}

function isSelected(item, inventoryName) {
    if (!state.selectedItem || state.selectedInventory !== inventoryName) return false;
    const selected = normalizeItem(state.selectedItem);
    return selected.id === item.id && selected.name === item.name && selected.type === item.type;
}

function cleanImageName(value) {
    const stripped = String(value || "placeholder")
        .replace(/\\/g, "/")
        .split("/")
        .pop()
        .replace(/\.(png|webp|jpg|jpeg)$/i, "")
        .replace(/[^A-Za-z0-9_.-]/g, "");

    return stripped || "placeholder";
}

function normalizeType(type) {
    const lowered = String(type || "main").toLowerCase();
    if (lowered === "container") return "container";
    return lowered;
}

function numberOrZero(value) {
    const number = Number(value);
    return Number.isFinite(number) ? number : 0;
}

function stripHtml(value) {
    return value.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
}

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

function generateId() {
    if (typeof crypto !== "undefined" && crypto.randomUUID) return crypto.randomUUID();
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (char) => {
        const random = Math.random() * 16 | 0;
        const value = char === "x" ? random : (random & 0x3) | 0x8;
        return value.toString(16);
    });
}

function encodeHash(value) {
    try {
        return btoa(value);
    } catch (error) {
        return value;
    }
}

function getResourceName() {
    if (typeof GetParentResourceName === "function") return GetParentResourceName();
    return "nx_inventory";
}

function bindEvents() {
    window.addEventListener("message", handleMessage);
    document.addEventListener("click", (event) => {
        if (!els.contextMenu.contains(event.target)) closeContextMenu();
    });
    document.addEventListener("keydown", (event) => {
        if (event.key === "Escape") {
            if (!els.playerModal.classList.contains("is-hidden")) return closePlayerModal();
            if (!els.quantityModal.classList.contains("is-hidden")) return closeQuantityModal();
            postNui("NUIFocusOff", {});
        }
    });
    els.playerModalClose.addEventListener("click", closePlayerModal);
    els.quantityClose.addEventListener("click", closeQuantityModal);
    els.quantityForm.addEventListener("submit", submitQuantity);
}

function init() {
    cacheElements();
    bindEvents();
    requestActionsConfig();
    renderInventory();
    renderFastSlots();
    renderWeight();
    renderMoney();
    renderPlayerId();
    renderSelectedItem();
    renderSecondaryInventory();
}

document.addEventListener("DOMContentLoaded", init);

window.nxInventory = {
    state,
    setVisible,
    renderInventory,
    renderFastSlots,
    renderWeight,
    renderMoney,
    renderPlayerId,
    renderSelectedItem,
    renderActions,
    postNui,
    safeGetItemImage,
};
