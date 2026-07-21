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
    categoryFilter: "all",
    sortMode: "category",
    favorites: {},
    context: null,
    dragPayload: null,
    manualDropTarget: null,
    language: {},
    config: {
        DoubleClickToUse: true,
        UseWeight: false,
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
        ignoreItemStackLimit: false,
        ids: {},
    },
    pendingGive: null,
    pendingQuantity: null,
    pendingConfirm: null,
    preferenceSaveTimer: null,
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

// เซ็ตนี้คุมว่าช่องขวา "ลากเข้าออกได้ไหม" — ถ้าไม่อยู่ในนี้จะเหลือแค่ปุ่ม take/move
// เพิ่ม "steal" เข้ามา: กระเป๋าผู้เล่นที่แอดมินเปิด (MJ-Admin) ควรลากได้เหมือนตู้ล็อคเกอร์
// ตัว callback ของ steal มีครบอยู่แล้วใน secondaryCallbacks ด้านบน ขาดแค่ไม่ได้ขึ้นทะเบียนตรงนี้
const draggableSecondaryTypes = new Set(["custom", "horse", "cart", "house", "bank", "hideout", "clan", "container", "steal"]);
const groupCategories = {
    2: "medical",
    3: "foods",
    4: "tools",
    5: "weapons",
    6: "ammo",
    7: "documents",
    8: "animals",
    9: "valuables",
    10: "horse",
    11: "herbs",
};
const categoryOrder = ["medical", "foods", "weapons", "ammo", "tools", "animals", "documents", "valuables", "horse", "herbs", "other"];
// หมวดที่โชว์เป็น pill จริงบน UI (7 อันตามที่ลูกค้ากำหนด) — หมวดอื่นดูรวมใน "ทั้งหมด"
const pillCategories = ["all", "foods", "weapons", "ammo", "medical", "tools", "valuables"];

function setActiveCategoryPill(cat) {
    if (!els.inventoryCategory) return;
    els.inventoryCategory.querySelectorAll(".cat-pill").forEach((pill) => {
        pill.classList.toggle("is-active", pill.dataset.cat === cat);
    });
}

function cacheElements() {
    els.root = document.getElementById("inventory-root");
    els.inventoryClose = document.getElementById("inventory-close");
    els.fastSlots = document.getElementById("fast-slots");
    els.inventoryGridWrap = document.getElementById("inventory-grid-wrap");
    els.inventoryGrid = document.getElementById("inventory-grid");
    els.inventoryEmpty = document.getElementById("inventory-empty");
    els.inventorySearch = document.getElementById("inventory-search");
    els.inventoryCategory = document.getElementById("inventory-category");
    els.inventorySort = document.getElementById("inventory-sort");
    els.weightFill = document.getElementById("weight-fill");
    els.weightText = document.getElementById("weight-text");
    els.moneyValue = document.getElementById("money-value");
    els.giveMoney = document.getElementById("give-money-btn");
    els.playerId = document.getElementById("player-id");
    els.selectedPanel = document.getElementById("selected-panel");
    els.selectedName = document.getElementById("selected-name");
    els.selectedMeta = document.getElementById("selected-meta");
    els.actionStrip = document.getElementById("action-strip");
    els.contextMenu = document.getElementById("context-menu");
    els.itemTooltip = document.getElementById("item-tooltip");
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
    els.quantityMin = document.getElementById("quantity-min");
    els.quantityMax = document.getElementById("quantity-max");
    els.confirmModal = document.getElementById("confirm-modal");
    els.confirmClose = document.getElementById("confirm-close");
    els.confirmTitle = document.getElementById("confirm-title");
    els.confirmMessage = document.getElementById("confirm-message");
    els.confirmCancel = document.getElementById("confirm-cancel");
    els.confirmAccept = document.getElementById("confirm-accept");
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
        closeConfirmModal();
        hideItemTooltip();
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
    const items = sortInventoryItems(normalizeList(state.secondaryItems));
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
            bindDragSource(button, {
                source: "fast-slot",
                slot: slot.slot,
                item: normalized,
            });
        }

        bindFastSlotDropTarget(button, slot.slot);

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

function beginFastSlotDrag(event, payload, element) {
    payload.all = Boolean(event.shiftKey || event.originalEvent?.shiftKey);
    state.dragPayload = payload;
    state.manualDropTarget = null;
    element.classList.add("is-dragging");
    document.body.classList.add("is-dragging");
    hideItemTooltip();
    closeContextMenu();

    if (event.dataTransfer) {
        event.dataTransfer.effectAllowed = payload.source === "fast-slot" ? "move" : "copyMove";
        event.dataTransfer.setData("text/plain", JSON.stringify({
            source: payload.source,
            slot: payload.slot || null,
            name: payload.item?.name || "",
        }));
    }
}

function endFastSlotDrag() {
    state.dragPayload = null;
    state.manualDropTarget = null;
    document.body.classList.remove("is-dragging");
    document.querySelectorAll(".is-dragging, .is-drop-target, .is-drop-blocked").forEach((element) => {
        element.classList.remove("is-dragging", "is-drop-target", "is-drop-blocked");
    });
    hideItemTooltip();
}

function handleFastSlotDrop(targetSlot, droppedPayload) {
    const payload = droppedPayload || state.dragPayload;
    endFastSlotDrag();
    if (!payload || !payload.item) return;

    if (payload.source === "fast-slot") {
        moveFastSlot(payload.slot, targetSlot);
        return;
    }

    if (payload.source === "main-inventory" && isFastSlotEligible(payload.item)) {
        assignItemToFastSlot(payload.item, targetSlot);
    }
}

function getJqueryDragDrop() {
    const jq = window.jQuery;
    if (!jq || !jq.fn || typeof jq.fn.draggable !== "function") return null;
    return jq;
}

function clearManualDropTarget() {
    const previous = state.manualDropTarget;
    if (previous?.element) {
        previous.element.classList.remove("is-drop-target", "is-drop-blocked");
    }
    state.manualDropTarget = null;
}

function setManualDropTarget(target) {
    const previous = state.manualDropTarget;
    if (previous?.element && previous.element !== target?.element) {
        previous.element.classList.remove("is-drop-target", "is-drop-blocked");
    }

    state.manualDropTarget = target || null;
    if (!target?.element) return;

    target.element.classList.toggle("is-drop-target", Boolean(target.allowed));
    target.element.classList.toggle("is-drop-blocked", !target.allowed);
}

function getDragPointer(event, helper) {
    const helperElement = helper?.jquery ? helper[0] : helper;
    if (helperElement && typeof helperElement.getBoundingClientRect === "function") {
        const rect = helperElement.getBoundingClientRect();
        if (rect.width > 0 && rect.height > 0) {
            return {
                clientX: rect.left + (rect.width / 2),
                clientY: rect.top + (rect.height / 2),
            };
        }
    }

    const original = event?.originalEvent || event || {};
    const clientX = Number(original.clientX ?? event?.clientX);
    const clientY = Number(original.clientY ?? event?.clientY);
    if (!Number.isFinite(clientX) || !Number.isFinite(clientY)) return null;
    return { clientX, clientY };
}

function resolveManualDropTarget(event, payload, helper) {
    const pointer = getDragPointer(event, helper);
    if (!pointer || !payload) return null;

    const hit = document.elementFromPoint(pointer.clientX, pointer.clientY);
    if (!hit || typeof hit.closest !== "function") return null;

    const fastSlot = hit.closest(".fast-slot");
    if (fastSlot && els.fastSlots.contains(fastSlot)) {
        const accepted = payload.source === "fast-slot" || payload.source === "main-inventory";
        const allowed = accepted && (payload.source === "fast-slot" || isFastSlotEligible(payload.item));
        return {
            kind: "fast-slot",
            element: fastSlot,
            slot: numberOrZero(fastSlot.dataset.slot),
            allowed,
        };
    }

    if (hit.closest("#secondary-grid")) {
        const accepted = payload.source === "main-inventory" && draggableSecondaryTypes.has(state.type);
        return {
            kind: "secondary-grid",
            element: els.secondaryGrid,
            allowed: accepted && getTransferMax("move", payload.item) > 0,
        };
    }

    if (hit.closest("#inventory-grid")) {
        if (payload.source === "fast-slot") {
            return { kind: "inventory-grid", element: els.inventoryGrid, allowed: true };
        }

        if (payload.source === "secondary-inventory") {
            const accepted = draggableSecondaryTypes.has(state.type);
            return {
                kind: "inventory-grid",
                element: els.inventoryGrid,
                allowed: accepted && getTransferMax("take", payload.item) > 0,
            };
        }
    }

    return null;
}

function updateManualDropTarget(event, payload, helper) {
    const target = resolveManualDropTarget(event, payload, helper);
    if (target) {
        setManualDropTarget(target);
    } else {
        clearManualDropTarget();
    }
}

function handleManualDrop(payload, target) {
    if (!payload || !target?.allowed) {
        endFastSlotDrag();
        return;
    }

    if (target.kind === "fast-slot" && target.slot) {
        handleFastSlotDrop(target.slot, payload);
        return;
    }

    if (target.kind === "secondary-grid") {
        handleInventoryDrop("move", payload);
        return;
    }

    if (target.kind === "inventory-grid") {
        handleMainInventoryDrop(payload);
        return;
    }

    endFastSlotDrag();
}

function createDragHelper(element) {
    const jq = getJqueryDragDrop();
    if (!jq) return element.cloneNode(true);

    const helper = document.createElement("div");
    helper.className = "drag-helper";
    const image = element.querySelector("img");
    if (image) {
        const clone = image.cloneNode(false);
        clone.draggable = false;
        helper.appendChild(clone);
    }
    return jq(helper);
}

function bindDragSource(element, payload) {
    const jq = getJqueryDragDrop();
    if (jq) {
        element.draggable = false;
        const draggable = jq(element);
        if (draggable.hasClass("ui-draggable")) draggable.draggable("destroy");
        draggable.data("nxDragPayload", payload).draggable({
            helper() {
                return createDragHelper(this);
            },
            appendTo: "body",
            zIndex: 100001,
            cursorAt: { top: 32, left: 32 },
            distance: 4,
            revert(dropped) {
                return !dropped && !state.manualDropTarget?.allowed;
            },
            revertDuration: 120,
            scroll: false,
            cancel: ".favorite-star",
            start(event) {
                beginFastSlotDrag(event, payload, element);
            },
            drag(event, ui) {
                updateManualDropTarget(event, payload, ui?.helper);
            },
            stop(event, ui) {
                if (!state.dragPayload) {
                    endFastSlotDrag();
                    return;
                }

                const resolved = resolveManualDropTarget(event, payload, ui?.helper);
                if (resolved) setManualDropTarget(resolved);
                const target = state.manualDropTarget;
                handleManualDrop(payload, target);
            },
        });
        return;
    }

    element.draggable = true;
    element.addEventListener("dragstart", (event) => beginFastSlotDrag(event, payload, element));
    element.addEventListener("dragend", endFastSlotDrag);
}

function bindFastSlotDropTarget(element, targetSlot) {
    if (getJqueryDragDrop()) return;

    element.addEventListener("dragover", (event) => {
        if (!state.dragPayload || !["fast-slot", "main-inventory"].includes(state.dragPayload.source)) return;
        event.preventDefault();
        const allowed = state.dragPayload.source === "fast-slot" || isFastSlotEligible(state.dragPayload.item);
        event.dataTransfer.dropEffect = state.dragPayload.source === "fast-slot" ? "move" : "copy";
        element.classList.toggle("is-drop-target", allowed);
        element.classList.toggle("is-drop-blocked", !allowed);
    });
    element.addEventListener("dragleave", (event) => {
        if (!element.contains(event.relatedTarget)) element.classList.remove("is-drop-target", "is-drop-blocked");
    });
    element.addEventListener("drop", (event) => {
        event.preventDefault();
        handleFastSlotDrop(targetSlot);
    });
}

function bindInventoryDropZone(element, acceptedSource, direction) {
    if (getJqueryDragDrop()) return;

    element.addEventListener("dragover", (event) => {
        const payload = state.dragPayload;
        if (!payload || payload.source !== acceptedSource || !draggableSecondaryTypes.has(state.type)) return;

        event.preventDefault();
        event.dataTransfer.dropEffect = "move";
        const allowed = getTransferMax(direction, payload.item) > 0;
        element.classList.toggle("is-drop-target", allowed);
        element.classList.toggle("is-drop-blocked", !allowed);
    });

    element.addEventListener("dragleave", (event) => {
        if (!element.contains(event.relatedTarget)) {
            element.classList.remove("is-drop-target", "is-drop-blocked");
        }
    });

    element.addEventListener("drop", (event) => {
        const payload = state.dragPayload;
        if (!payload || payload.source !== acceptedSource || !draggableSecondaryTypes.has(state.type)) return;

        event.preventDefault();
        handleInventoryDrop(direction, payload);
    });
}

function bindMainInventoryDropZone(element) {
    if (getJqueryDragDrop()) return;

    element.addEventListener("dragover", (event) => {
        const payload = state.dragPayload;
        if (!payload) return;

        const allowed = payload.source === "fast-slot"
            || (payload.source === "secondary-inventory"
                && draggableSecondaryTypes.has(state.type)
                && getTransferMax("take", payload.item) > 0);
        if (payload.source !== "fast-slot" && payload.source !== "secondary-inventory") return;

        event.preventDefault();
        event.dataTransfer.dropEffect = "move";
        element.classList.toggle("is-drop-target", allowed);
        element.classList.toggle("is-drop-blocked", !allowed);
    });

    element.addEventListener("dragleave", (event) => {
        if (!element.contains(event.relatedTarget)) {
            element.classList.remove("is-drop-target", "is-drop-blocked");
        }
    });

    element.addEventListener("drop", (event) => {
        const payload = state.dragPayload;
        if (!payload || !["fast-slot", "secondary-inventory"].includes(payload.source)) return;
        event.preventDefault();
        handleMainInventoryDrop(payload);
    });
}

function handleMainInventoryDrop(payload) {
    if (!payload) return;

    if (payload.source === "fast-slot") {
        const sourceSlot = numberOrZero(payload.slot);
        endFastSlotDrag();
        if (sourceSlot) removeFastSlot(sourceSlot);
        return;
    }

    if (payload.source === "secondary-inventory") {
        handleInventoryDrop("take", payload);
    }
}

function handleInventoryDrop(direction, payload) {
    if (!payload || !payload.item || !draggableSecondaryTypes.has(state.type)) return;

    const max = getTransferMax(direction, payload.item);
    const moveAll = payload.all;
    const item = payload.item;
    endFastSlotDrag();

    if (max <= 0) {
        postNui("TransferLimitExceeded", { max: 0 });
        return;
    }

    if (moveAll) {
        moveTakeSelected(direction, normalizeItem(item), max);
    } else {
        beginMoveTake(direction, item);
    }
}

function renderWeight() {
    if (!state.config.UseWeight) {
        const limits = new Map();
        normalizeList(state.inventoryItems).forEach((entry) => {
            const item = normalizeItem(entry);
            const limit = numberOrZero(item.limit);
            if (item.type === "item_weapon" || limit <= 0) return;

            const key = String(item.name).toLowerCase();
            const current = limits.get(key) || { count: 0, limit };
            current.count += numberOrZero(item.count);
            current.limit = limit;
            limits.set(key, current);
        });

        const limitedItems = Array.from(limits.values());
        const fullItems = limitedItems.filter((item) => item.count >= item.limit).length;
        const pct = limitedItems.length > 0 ? (fullItems / limitedItems.length) * 100 : 0;

        els.weightFill.style.width = `${Math.max(0, Math.min(100, pct))}%`;
        els.weightFill.classList.toggle("is-over", false);
        els.weightText.textContent = `LIMITS ${fullItems}/${limitedItems.length} FULL`;
        return;
    }

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
        if (isFastSlotEligible(item)) {
            actions.push({ label: "Slot", handler: () => addSelectedToFastSlot(item) });
        }
        if (selectedItemIsInSelectedSlot(item)) {
            actions.push({ label: "Clear", handler: () => removeFastSlot(state.selectedSlot) });
        }
    } else {
        actions.push({ label: "Take", handler: () => beginMoveTake("take", item) });
    }
    actions.push({ label: isFavorite(item) ? "Unfavorite" : "Favorite", handler: () => toggleFavorite(item) });

    actions.forEach((action) => {
        const button = document.createElement("button");
        button.type = "button";
        button.textContent = action.label;
        button.addEventListener("click", action.handler);
        els.actionStrip.appendChild(button);
    });
}

// A modal counts as open only when it exists and is not hidden. Tolerating a
// missing element keeps a hotkey from dying on a page that lacks that modal.
function isModalOpen(modal) {
    return Boolean(modal) && !modal.classList.contains("is-hidden");
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

    if (isFavorite(normalized)) {
        button.insertAdjacentHTML("beforeend", `<span class="favorite-star" aria-hidden="true">★</span>`);
    }

    if (normalized.used || normalized.used2) {
        button.insertAdjacentHTML("beforeend", `<span class="equipped-dot"></span>`);
    }

    const amount = formatAmount(normalized, false, inventoryName);
    if (amount) {
        button.insertAdjacentHTML("beforeend", `<span class="item-amount">${escapeHtml(amount)}</span>`);
    }

    button.appendChild(createImage(normalized, normalized.label));
    button.insertAdjacentHTML("beforeend", `<span class="item-label">${escapeHtml(normalized.label)}</span>`);

    if (inventoryName === "main" || draggableSecondaryTypes.has(state.type)) {
        bindDragSource(button, {
            source: inventoryName === "main" ? "main-inventory" : "secondary-inventory",
            item: normalized,
        });
    }

    button.addEventListener("mouseenter", (event) => showItemTooltip(normalized, event, inventoryName));
    button.addEventListener("mousemove", positionItemTooltip);
    button.addEventListener("mouseleave", hideItemTooltip);

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
    hideItemTooltip();
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
    entries.push({ label: isFavorite(item) ? "Unfavorite" : "Favorite", handler: () => toggleFavorite(item) });

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

// มอบเงินให้ผู้เล่นใกล้ๆ — reuse pipeline เดิม (GetNearPlayers -> showPlayerModal -> GiveItem)
// ทำเงินเป็น "ไอเทม" ชนิด item_money แล้วส่งผ่านท่อเดียวกับการมอบไอเทม
// ฝั่ง Lua (NUIService.NUIGiveItem) เห็น type === "item_money" จะยิง giveMoneyToPlayer เอง — ไม่ต้องแก้ server
function beginGiveMoney() {
    const max = Math.floor(numberOrZero(state.money));
    if (max <= 0) return;
    const title = (state.language && state.language.givemoney) || "มอบเงิน";
    openQuantityModal(title, max, (qty) => {
        const amount = Math.floor(numberOrZero(qty));
        if (amount <= 0 || amount > max) return;
        requestNearPlayers({
            name: "money",
            item: "money",
            type: "item_money",
            id: 0,
            hash: 0,
            count: amount,
            metadata: null,
            degradation: null,
        }, amount);
    }, { ignoreTransferLimit: true });
}

function beginDrop(item) {
    const normalized = normalizeItem(item);
    const confirmDrop = (qty) => {
        openConfirmModal(
            "Discard item",
            `Discard ${qty} x ${normalized.label}? This action cannot be undone.`,
            () => dropSelected(normalized, qty),
        );
    };

    if (normalized.type === "item_weapon" || normalized.count <= 1) {
        confirmDrop(1);
        return;
    }

    openQuantityModal("Drop amount", normalized.count, confirmDrop);
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
    const max = getTransferMax(direction, normalized);
    if (max <= 0) {
        postNui("TransferLimitExceeded", { max: 0 });
        return;
    }
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

function getTransferMax(direction, item) {
    const normalized = normalizeItem(item);
    const isWeapon = normalized.type === "item_weapon";

    const globalCap = Math.max(1, Math.floor(numberOrZero(state.config.MaxItemTransferAmount) || normalized.count || 1));
    let max = isWeapon ? 1 : Math.min(Math.max(0, Math.floor(normalized.count)), globalCap);
    const itemLimit = Math.floor(numberOrZero(normalized.limit));

    if (direction === "move") {
        const inventoryLimit = Math.floor(numberOrZero(state.secondary.capacity));
        if (inventoryLimit > 0) {
            max = Math.min(max, Math.max(0, inventoryLimit - computeSecondaryUsedCount()));
        }

        if (!isWeapon && itemLimit > 0 && !state.secondary.ignoreItemStackLimit) {
            const storedCount = countItemByName(state.secondaryItems, normalized.name);
            max = Math.min(max, Math.max(0, itemLimit - storedCount));
        }
    } else if (direction === "take" && !isWeapon && itemLimit > 0) {
        const carriedCount = countItemByName(state.inventoryItems, normalized.name);
        max = Math.min(max, Math.max(0, itemLimit - carriedCount));
    }

    return Math.max(0, Math.floor(max));
}

function countItemByName(items, name) {
    const key = String(name || "").toLowerCase();
    return normalizeList(items).reduce((total, entry) => {
        const item = normalizeItem(entry);
        if (String(item.name).toLowerCase() !== key) return total;
        return total + (item.type === "item_weapon" ? 1 : numberOrZero(item.count));
    }, 0);
}

function addSelectedToFastSlot(item) {
    const normalized = normalizeItem(item);
    if (!isFastSlotEligible(normalized)) return;
    const existingSlot = findFastSlotByItem(normalized);
    const slot = state.selectedSlot || existingSlot?.slot || firstAvailableFastSlot();

    if (!slot) return;

    assignItemToFastSlot(normalized, slot);
}

function assignItemToFastSlot(item, slot) {
    const normalized = normalizeItem(item);
    const itemKey = fastSlotItemKey(normalized);

    state.fastSlots = normalizeFastSlots().map((entry) => {
        if (entry.slot === slot) return { slot, item: normalized };
        if (entry.item && fastSlotItemKey(entry.item) === itemKey) return { slot: entry.slot, item: null };
        return entry;
    });
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

function moveFastSlot(fromSlot, toSlot) {
    const sourceSlot = numberOrZero(fromSlot);
    const targetSlot = numberOrZero(toSlot);
    if (!sourceSlot || !targetSlot || sourceSlot === targetSlot) return;

    const slots = normalizeFastSlots();
    const source = slots.find((entry) => entry.slot === sourceSlot);
    const target = slots.find((entry) => entry.slot === targetSlot);
    if (!source?.item) return;

    state.fastSlots = slots.map((entry) => {
        if (entry.slot === sourceSlot) return { slot: sourceSlot, item: target?.item || null };
        if (entry.slot === targetSlot) return { slot: targetSlot, item: source.item };
        return entry;
    });
    state.selectedSlot = targetSlot;
    renderFastSlots();
    postNui("MoveFastSlot", { fromSlot: sourceSlot, toSlot: targetSlot });
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

function openQuantityModal(title, max, onSubmit, options) {
    const opts = options || {};
    const hardMax = numberOrZero(max) || 1;
    // เงิน (ignoreTransferLimit) ไม่ควรโดน cap ของ "การโอนไอเทม" (MaxItemTransferAmount=200)
    // เพราะเงินหลักพัน — ให้ cap ด้วยยอดที่มีจริงเท่านั้น (server ตรวจซ้ำอีกชั้น)
    const limit = opts.ignoreTransferLimit
        ? hardMax
        : Math.min(hardMax, numberOrZero(state.config.MaxItemTransferAmount) || hardMax);
    const cappedMax = Math.max(1, limit);
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

function setQuantityPreset(useMaximum) {
    const min = Math.max(1, Math.floor(numberOrZero(els.quantityInput.min) || 1));
    const max = Math.max(min, Math.floor(numberOrZero(els.quantityInput.max) || min));
    els.quantityInput.value = String(useMaximum ? max : min);
    els.quantityInput.focus();
    els.quantityInput.select();
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

function openConfirmModal(title, message, onConfirm) {
    state.pendingConfirm = onConfirm;
    els.confirmTitle.textContent = title || "Confirm";
    els.confirmMessage.textContent = message || "Are you sure?";
    els.confirmModal.classList.remove("is-hidden");
    setTimeout(() => els.confirmAccept.focus(), 0);
}

function closeConfirmModal() {
    els.confirmModal.classList.add("is-hidden");
    state.pendingConfirm = null;
}

function acceptConfirmation() {
    const callback = state.pendingConfirm;
    closeConfirmModal();
    if (callback) callback();
}

function preferenceItemKey(item) {
    return String(normalizeItem(item).name || "").trim().toLowerCase();
}

function isFavorite(item) {
    return Boolean(state.favorites[preferenceItemKey(item)]);
}

function toggleFavorite(item) {
    const key = preferenceItemKey(item);
    if (!key) return;

    if (state.favorites[key]) {
        delete state.favorites[key];
    } else {
        state.favorites[key] = true;
    }

    saveInventoryPreferences();
    renderInventory();
    renderSecondaryInventory();
    renderActions();
}

function saveInventoryPreferences() {
    if (state.preferenceSaveTimer) clearTimeout(state.preferenceSaveTimer);
    state.preferenceSaveTimer = setTimeout(() => {
        state.preferenceSaveTimer = null;
        postNui("SetInventoryPreferences", {
            sortMode: state.sortMode,
            categoryFilter: state.categoryFilter,
            favorites: Object.keys(state.favorites).filter((key) => state.favorites[key]),
        });
    }, 200);
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
            renderWeight();
            break;
        case "setSecondInventoryItems":
            state.secondaryItems = normalizeList(data.itemList || data.items || []);
            state.secondary.ids.info = data.info;
            renderSecondaryInventory();
            break;
        case "changecheck":
            state.weight = numberOrZero(data.check ?? data.weight ?? data.current);
            state.maxWeight = numberOrZero(data.info ?? data.maxWeight ?? data.capacity);
            if (data.useWeight !== undefined) state.config.UseWeight = Boolean(data.useWeight);
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
        case "inventoryPreferences":
            applyInventoryPreferences(data.preferences || data);
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
        state.secondary.ignoreItemStackLimit = false;
    } else {
        state.secondary.visible = true;
        state.secondary.title = data.title || data.name || state.type;
        state.secondary.capacity = data.capacity ?? null;
        state.secondary.weight = data.weight ?? null;
        state.secondary.ignoreItemStackLimit = data.ignoreItemStackLimit === true;
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

    const seenItems = new Set();
    next.forEach((entry) => {
        if (!entry.item) return;
        const key = fastSlotItemKey(entry.item);
        if (seenItems.has(key)) {
            entry.item = null;
            return;
        }
        seenItems.add(key);
    });

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
    let list = normalizeList(items);
    const query = String(state.searchText || "").trim().toLowerCase();

    if (query) {
        list = list.filter((item) => {
            const normalized = normalizeItem(item);
            return normalized.name.toLowerCase().includes(query) || normalized.label.toLowerCase().includes(query);
        });
    }

    if (state.categoryFilter !== "all") {
        list = list.filter((item) => getItemCategory(item) === state.categoryFilter);
    }

    return sortInventoryItems(list);
}

function getItemCategory(item) {
    const normalized = normalizeItem(item);
    if (normalized.type === "item_weapon") return "weapons";
    return groupCategories[Math.floor(numberOrZero(normalized.group))] || "other";
}

function sortInventoryItems(items) {
    return normalizeList(items).slice().sort((leftEntry, rightEntry) => {
        const left = normalizeItem(leftEntry);
        const right = normalizeItem(rightEntry);
        const favoriteDelta = Number(isFavorite(right)) - Number(isFavorite(left));
        if (favoriteDelta !== 0) return favoriteDelta;

        if (state.sortMode === "count") {
            const countDelta = numberOrZero(right.count) - numberOrZero(left.count);
            if (countDelta !== 0) return countDelta;
        } else if (state.sortMode === "category") {
            const leftCategory = categoryOrder.indexOf(getItemCategory(left));
            const rightCategory = categoryOrder.indexOf(getItemCategory(right));
            const categoryDelta = (leftCategory < 0 ? 999 : leftCategory) - (rightCategory < 0 ? 999 : rightCategory);
            if (categoryDelta !== 0) return categoryDelta;
        }

        return left.label.localeCompare(right.label, undefined, { sensitivity: "base" });
    });
}

function applyInventoryPreferences(preferences) {
    const source = preferences && typeof preferences === "object" ? preferences : {};
    const favorites = Array.isArray(source.favorites) ? source.favorites : [];
    state.sortMode = ["category", "name", "count"].includes(source.sortMode) ? source.sortMode : "category";
    // จำกัดให้เหลือเฉพาะหมวดที่มี pill จริง (7 อัน) — ค่าที่ saved ไว้เป็นหมวดเก่าที่ตัดออก
    // (animals/documents/horse/herbs/other) ให้ตกเป็น "all" ไม่งั้นจะกรองค้างโดยไม่มี pill ไฮไลต์
    state.categoryFilter = pillCategories.includes(source.categoryFilter) ? source.categoryFilter : "all";
    state.favorites = {};
    favorites.forEach((name) => {
        const key = String(name || "").trim().toLowerCase();
        if (key) state.favorites[key] = true;
    });

    els.inventorySort.value = state.sortMode;
    setActiveCategoryPill(state.categoryFilter);
    renderInventory();
    renderSecondaryInventory();
    renderActions();
}

function formatAmount(item, fastSlot, inventoryName) {
    if (item.type === "item_weapon") return item.count > 0 && !fastSlot ? String(item.count) : "";
    const count = numberOrZero(item.count);
    const limit = numberOrZero(item.limit);
    if (inventoryName === "second" && state.secondary.ignoreItemStackLimit) {
        return count > 0 ? String(count) : "";
    }
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

// ตู้ custom inventory แบบจำกัด "จำนวนชิ้น" (ไม่ได้ตั้ง useweight ฝั่ง server) ไม่เคยส่งค่า weight มาเลย
// (server ส่ง weight=nil เสมอสำหรับเคสนี้) เลยต้องรวมจำนวนจากไอเทมที่ NUI มีอยู่จริงเอง ให้ตรงกับที่ server
// ใช้เช็ค limit จริง (InventoryService.getInventoryTotalCount: sum ของ count ทุกชิ้น + 1 ต่ออาวุธ 1 กระบอก)
function computeSecondaryUsedCount() {
    const items = Array.isArray(state.secondaryItems) ? state.secondaryItems : [];
    return items.reduce((total, item) => total + (item.type === "item_weapon" ? 1 : numberOrZero(item.count)), 0);
}

function formatSecondaryCapacity() {
    const used = formatNumber(computeSecondaryUsedCount());
    const capacity = state.secondary.capacity !== null ? formatNumber(state.secondary.capacity) : "";
    return capacity ? `${used}/${capacity}` : used;
}

function buildSelectedMeta(item) {
    const pieces = [];
    if (item.type === "item_weapon" && item.serial_number) pieces.push(`Serial ${item.serial_number}`);
    if (state.config.UseWeight && item.weight !== undefined) pieces.push(`${formatNumber(item.weight)} ${String(state.config.WeightMeasure || "KG").toUpperCase()}`);
    if (item.metadata && item.metadata.description) pieces.push(stripHtml(String(item.metadata.description)));
    if (item.desc) pieces.push(stripHtml(String(item.desc)));
    return pieces.filter(Boolean).join(" / ");
}

function showItemTooltip(item, event, inventoryName) {
    if (!els.contextMenu.classList.contains("is-hidden")) {
        hideItemTooltip();
        return;
    }

    const normalized = normalizeItem(item);
    const unit = String(state.config.WeightMeasure || "KG").toUpperCase();
    const rows = [];
    const category = getItemCategory(normalized);
    const count = normalized.type === "item_weapon" ? 1 : numberOrZero(normalized.count);
    const limit = numberOrZero(normalized.limit);
    const weight = numberOrZero(normalized.weight);
    const durability = normalized.percentage ?? normalized.metadata?.durability ?? normalized.metadata?.quality;
    const serial = normalized.serial_number || normalized.metadata?.serial_number || normalized.metadata?.serial;
    const description = normalized.metadata?.description || normalized.desc || normalized.custom_desc;

    rows.push(["Category", category]);
    const ignoresStackLimit = inventoryName === "second" && state.secondary.ignoreItemStackLimit;
    rows.push(["Amount", limit > 0 && !ignoresStackLimit ? `${count}/${limit}` : String(count)]);
    if (state.config.UseWeight && weight > 0) {
        rows.push(["Weight", `${formatNumber(weight)} ${unit}`]);
        rows.push(["Total", `${formatNumber(weight * count)} ${unit}`]);
    }
    if (durability !== undefined && durability !== null && durability !== "") rows.push(["Durability", `${formatNumber(durability)}%`]);
    if (serial) rows.push(["Serial", String(serial)]);

    els.itemTooltip.innerHTML = `
        <strong>${escapeHtml(normalized.label)}${isFavorite(normalized) ? " ★" : ""}</strong>
        ${rows.map(([label, value]) => `<div class="item-tooltip-row"><span>${escapeHtml(label)}</span><span>${escapeHtml(value)}</span></div>`).join("")}
        ${description ? `<div class="item-tooltip-desc">${escapeHtml(stripHtml(String(description)))}</div>` : ""}
    `;
    els.itemTooltip.classList.remove("is-hidden");
    positionItemTooltip(event);
}

function positionItemTooltip(event) {
    if (!event || els.itemTooltip.classList.contains("is-hidden")) return;
    const x = Math.min(window.innerWidth - 205, event.clientX + 14);
    const y = Math.min(window.innerHeight - 130, event.clientY + 14);
    els.itemTooltip.style.left = `${Math.max(6, x)}px`;
    els.itemTooltip.style.top = `${Math.max(6, y)}px`;
}

function hideItemTooltip() {
    if (!els.itemTooltip) return;
    els.itemTooltip.classList.add("is-hidden");
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

function fastSlotItemKey(item) {
    return String(normalizeItem(item).name || "").trim().toLowerCase();
}

function isFastSlotEligible(item) {
    const normalized = normalizeItem(item);
    return normalized.type === "item_weapon" || normalized.canUse === true;
}

function findFastSlotByItem(item) {
    const itemKey = fastSlotItemKey(item);
    return normalizeFastSlots().find((entry) => entry.item && fastSlotItemKey(entry.item) === itemKey) || null;
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
            if (!els.confirmModal.classList.contains("is-hidden")) return closeConfirmModal();
            postNui("NUIFocusOff", {});
            return;
        }

        // Fast slots fire on 1-6 only while the inventory is open. The NUI holds
        // keyboard focus then, so the game never sees these keys; once it closes,
        // 1-6 go back to the game's own weapon selection untouched.
        if (!state.visible) return;
        if (event.repeat || event.ctrlKey || event.altKey || event.metaKey) return;
        if (isModalOpen(els.playerModal) || isModalOpen(els.quantityModal) || isModalOpen(els.confirmModal)) return;

        const target = event.target;
        if (target && (target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.isContentEditable)) return;

        const slot = Number(event.key);
        if (!Number.isInteger(slot) || slot < 1 || slot > state.fastSlots.length) return;

        event.preventDefault();
        postNui("UseFastSlot", { slot });
    });
    els.inventorySearch.addEventListener("input", () => {
        state.searchText = els.inventorySearch.value;
        renderInventory();
    });
    els.inventoryCategory.addEventListener("click", (event) => {
        const pill = event.target.closest(".cat-pill");
        if (!pill) return;
        const cat = pill.dataset.cat || "all";
        if (cat === state.categoryFilter) return;
        state.categoryFilter = cat;
        setActiveCategoryPill(cat);
        saveInventoryPreferences();
        renderInventory();
    });
    els.inventorySort.addEventListener("change", () => {
        state.sortMode = els.inventorySort.value;
        saveInventoryPreferences();
        renderInventory();
        renderSecondaryInventory();
    });
    if (els.giveMoney) {
        els.giveMoney.addEventListener("click", beginGiveMoney);
    }
    els.playerModalClose.addEventListener("click", closePlayerModal);
    els.quantityClose.addEventListener("click", closeQuantityModal);
    els.quantityMin.addEventListener("click", () => setQuantityPreset(false));
    els.quantityMax.addEventListener("click", () => setQuantityPreset(true));
    els.quantityForm.addEventListener("submit", submitQuantity);
    els.confirmClose.addEventListener("click", closeConfirmModal);
    els.confirmCancel.addEventListener("click", closeConfirmModal);
    els.confirmAccept.addEventListener("click", acceptConfirmation);
    els.inventoryClose.addEventListener("click", () => postNui("NUIFocusOff", {}));
    bindInventoryDropZone(els.secondaryGrid, "main-inventory", "move");
    bindMainInventoryDropZone(els.inventoryGrid);
}

function init() {
    cacheElements();
    bindEvents();
    requestActionsConfig();
    postNui("RequestInventoryPreferences", {});
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
