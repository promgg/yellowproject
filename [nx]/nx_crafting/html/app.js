(function () {
    "use strict";

    const isBrowserPreview = typeof GetParentResourceName !== "function";
    const resourceName = isBrowserPreview ? "nx_crafting" : GetParentResourceName();
    const defaultImageBase = "nui://vorp_inventory/html/img/items/";

    const state = {
        visible: false,
        categories: [],
        selectedCategoryIndex: 1,
        selectedItemIndex: 1,
        selectedRecipeIndex: 1,
        tableName: "Craft Table",
        imageBase: defaultImageBase,
        amount: 1,
        search: "",
        craftLocked: false,
        mockIcons: false,
        activeAudio: null,
        // สถานะพับ/ขยายของกลุ่มไอเทมในลิสต์ซ้าย (group = ชื่อรุ่นปืน) — key ต่อ category
        // รีเซ็ตทุกครั้งที่เปลี่ยนหมวด/เปิดเมนูใหม่ ให้กลุ่มของไอเทมที่เลือกอยู่กางเองอัตโนมัติ
        expandedGroups: {}
    };

    const els = {
        app: document.getElementById("app"),
        closeButton: document.getElementById("closeButton"),
        tableName: document.getElementById("tableName"),
        searchInput: document.getElementById("searchInput"),
        categoryList: document.getElementById("categoryList"),
        recipeList: document.getElementById("recipeList"),
        categoryTitle: document.getElementById("categoryTitle"),
        variantCards: document.getElementById("variantCards"),
        materialsList: document.getElementById("materialsList"),
        toolsList: document.getElementById("toolsList"),
        failedList: document.getElementById("failedList"),
        previewIcon: document.getElementById("previewIcon"),
        previewMeta: document.getElementById("previewMeta"),
        previewName: document.getElementById("previewName"),
        previewChance: document.getElementById("previewChance"),
        amountMinus: document.getElementById("amountMinus"),
        amountPlus: document.getElementById("amountPlus"),
        amountInput: document.getElementById("amountInput"),
        craftButton: document.getElementById("craftButton"),
        notificationToast: document.getElementById("notificationToast"),
        notificationText: document.getElementById("notificationText"),
        notificationClose: document.getElementById("notificationClose")
    };

    function postNui(callbackName, payload) {
        if (isBrowserPreview) {
            console.info("[nx_crafting mock]", callbackName, payload || {});
            if (callbackName === "Crafting") {
                window.setTimeout(function () {
                    showNotification("Mock craft request sent. Check the console for payload details.");
                }, 120);
            }
            return;
        }

        fetch(`https://${resourceName}/${callbackName}`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=UTF-8"
            },
            body: JSON.stringify(payload || {})
        }).catch(function () {});
    }

    function numeric(value, fallback) {
        const number = Number(value);
        return Number.isFinite(number) ? number : fallback;
    }

    function sameIndex(a, b) {
        return String(a) === String(b);
    }

    function toArray(value) {
        if (!value) {
            return [];
        }
        if (Array.isArray(value)) {
            return value.filter(Boolean);
        }
        if (typeof value === "object") {
            return Object.keys(value)
                .sort(function (a, b) {
                    const na = Number(a);
                    const nb = Number(b);
                    if (Number.isFinite(na) && Number.isFinite(nb)) {
                        return na - nb;
                    }
                    return String(a).localeCompare(String(b));
                })
                .map(function (key) {
                    return value[key];
                })
                .filter(Boolean);
        }
        return [];
    }

    function normalizeImageBase(base) {
        if (!base || typeof base !== "string") {
            return defaultImageBase;
        }
        return base.endsWith("/") ? base : `${base}/`;
    }

    function formatCount(value) {
        const number = numeric(value, 0);
        if (Math.abs(number) >= 1000) {
            return Math.round(number).toLocaleString("en-US");
        }
        if (Number.isInteger(number)) {
            return String(number);
        }
        return String(Math.round(number * 100) / 100);
    }

    function clear(element) {
        while (element.firstChild) {
            element.removeChild(element.firstChild);
        }
    }

    function textElement(tag, className, text) {
        const element = document.createElement(tag);
        if (className) {
            element.className = className;
        }
        element.textContent = text || "";
        return element;
    }

    function emptyState(text) {
        return textElement("div", "empty-state", text);
    }

    function fallbackText(name, label) {
        const key = String(name || "").toLowerCase();
        if (key === "money") {
            return "$";
        }
        if (key === "gold") {
            return "G";
        }
        if (key === "rol") {
            return "R";
        }
        const source = String(label || name || "?").trim();
        return source ? source.charAt(0).toUpperCase() : "?";
    }

    function imageUrl(name, image) {
        if (image && typeof image === "string") {
            if (/^(nui:\/\/|https?:\/\/|\.\/|\/)/i.test(image) || /\.(png|jpe?g|webp|gif)$/i.test(image)) {
                return image;
            }
            return `${state.imageBase}${image}`;
        }
        if (!name) {
            return "";
        }
        return `${state.imageBase}${name}.png`;
    }

    function createIcon(name, label, className, image) {
        const icon = document.createElement("div");
        icon.className = className ? `item-icon ${className}` : "item-icon";

        const img = document.createElement("img");
        img.alt = "";

        const fallback = document.createElement("span");
        fallback.className = "icon-fallback";
        fallback.textContent = fallbackText(name, label);

        const src = imageUrl(name, image);
        if (src && !state.mockIcons) {
            img.src = src;
            img.addEventListener("error", function () {
                icon.classList.add("is-missing");
            });
        } else {
            icon.classList.add("is-missing");
        }

        icon.appendChild(img);
        icon.appendChild(fallback);
        return icon;
    }

    function amountFromRow(row, fallback) {
        if (!row || typeof row !== "object") {
            return numeric(row, fallback);
        }
        return numeric(row.amox ?? row.amount ?? row.count ?? row.qty ?? row.quantity, fallback);
    }

    function normalizeRequirement(value, options) {
        const settings = Object.assign({
            defaultAmount: 0,
            defaultStatus: undefined
        }, options || {});

        if (!value) {
            return [];
        }

        if (Array.isArray(value)) {
            return value.map(function (row) {
                if (!row || typeof row !== "object") {
                    return null;
                }
                const amount = amountFromRow(row, settings.defaultAmount);
                return {
                    name: row.name || row.item || row.id,
                    label: row.label,
                    amox: amount,
                    status: row.status ?? row.required ?? settings.defaultStatus
                };
            }).filter(function (row) {
                return row && row.name && numeric(row.amox, 0) > 0;
            });
        }

        if (typeof value === "object") {
            return Object.keys(value).sort().map(function (key) {
                const row = value[key];
                if (row && typeof row === "object") {
                    const amount = amountFromRow(row, settings.defaultAmount);
                    return {
                        name: row.name || row.item || row.id || key,
                        label: row.label,
                        amox: amount,
                        status: row.status ?? row.required ?? settings.defaultStatus
                    };
                }
                return {
                    name: key,
                    amox: typeof row === "boolean" ? settings.defaultAmount : numeric(row, settings.defaultAmount),
                    status: typeof row === "boolean" ? row : settings.defaultStatus
                };
            }).filter(function (row) {
                return row && row.name && numeric(row.amox, 0) > 0;
            });
        }

        return [];
    }

    function normalizeTools(value) {
        return normalizeRequirement(value, {
            defaultAmount: 1,
            defaultStatus: true
        }).map(function (row) {
            if (row.status === undefined) {
                row.status = true;
            }
            return row;
        });
    }

    function recipeLabel(recipe) {
        if (!recipe) {
            return "Recipe";
        }
        if (recipe.recipeLabel) {
            return recipe.recipeLabel;
        }
        if (recipe.label || recipe.title) {
            return recipe.label || recipe.title;
        }
        if (recipe.variantCards) {
            const cards = toArray(recipe.variantCards);
            const card = cards[0] || recipe.variantCards;
            if (card && typeof card === "object") {
                return card.label || card.title || card.name || `Recipe ${recipe.recipeIndex || 1}`;
            }
        }
        return `Recipe ${recipe.recipeIndex || 1}`;
    }

    function isWeapon(item, recipe) {
        const type = recipe && recipe.type ? recipe.type : item && item.type;
        if (type === "item_weapon" || type === "WEAPON") {
            return true;
        }
        const name = item && item.item;
        return typeof name === "string" && name.toUpperCase().includes("WEAPON_");
    }

    function normalizeRecipe(rawRecipe, recipeIndex, item, category) {
        const recipe = Object.assign({}, rawRecipe || {});
        const index = numeric(recipe.recipeIndex, recipeIndex);
        recipe.recipeIndex = index;
        recipe.categoryIndex = category.categoryIndex;
        recipe.Category = category.categoryIndex;
        recipe.categoryname = category.name;
        recipe.itemIndex = item.itemIndex;
        recipe.id = item.itemIndex;
        recipe.item = item.item;
        recipe.type = recipe.type || item.type;
        recipe.recipeLabel = recipeLabel(Object.assign({ recipeIndex: index }, recipe));
        recipe.cost = normalizeRequirement(recipe.cost, { defaultAmount: 0 });
        recipe.blueprint = normalizeRequirement(recipe.blueprint, { defaultAmount: 0 });
        recipe.toolsList = normalizeTools(recipe.toolsList || recipe.equipment);
        recipe.equipment = recipe.toolsList;
        recipe.failedList = normalizeRequirement(recipe.failedList || recipe.fail_item, { defaultAmount: 0 });
        recipe.fail_item = recipe.failedList;
        return recipe;
    }

    function recipeEntriesForItem(rawItem) {
        const rawRecipes = rawItem.recipes || rawItem.recipe;
        if (rawRecipes) {
            return toArray(rawRecipes);
        }

        const recipe = Object.assign({}, rawItem);
        delete recipe.recipes;
        delete recipe.recipe;
        return [recipe];
    }

    function normalizeItem(rawItem, fallbackIndex, category) {
        const item = Object.assign({}, rawItem || {});
        item.categoryIndex = numeric(item.categoryIndex ?? item.Category, category.categoryIndex);
        item.Category = item.categoryIndex;
        item.categoryname = category.name;
        item.itemIndex = numeric(item.itemIndex ?? item.id, fallbackIndex);
        item.id = item.itemIndex;
        item.item = item.item || item.name;
        item.type = item.type || (String(item.item || "").toUpperCase().includes("WEAPON_") ? "item_weapon" : "item_standard");
        item.label = item.label || item.title || item.item || "Unknown Item";
        item.recipes = recipeEntriesForItem(rawItem).map(function (rawRecipe, index) {
            return normalizeRecipe(rawRecipe, index + 1, item, category);
        });
        if (!item.recipes.length) {
            item.recipes = [normalizeRecipe({}, 1, item, category)];
        }
        return item;
    }

    function categoryFromMeta(rawCategory, fallbackIndex) {
        const index = numeric(rawCategory.categoryIndex ?? rawCategory.Category ?? rawCategory.index, fallbackIndex);
        const name = rawCategory.name || rawCategory.categoryname || `Category ${index}`;
        return {
            categoryIndex: index,
            Category: index,
            name: name,
            categoryname: name,
            items: []
        };
    }

    function normalizePayload(payload) {
        const categories = [];
        const byIndex = {};
        const rawCategories = toArray(payload.categories || payload.datatype);

        rawCategories.forEach(function (rawCategory, index) {
            const category = categoryFromMeta(rawCategory || {}, index + 1);
            categories.push(category);
            byIndex[String(category.categoryIndex)] = category;

            const rawItems = rawCategory.items || rawCategory.list;
            if (rawItems) {
                toArray(rawItems).forEach(function (rawItem, itemIndex) {
                    category.items.push(normalizeItem(rawItem, itemIndex + 1, category));
                });
            }
        });

        toArray(payload.data).forEach(function (rawItem, index) {
            const categoryIndex = numeric(rawItem.categoryIndex ?? rawItem.Category, payload.categoryIndex ?? payload.category ?? 1);
            let category = byIndex[String(categoryIndex)];
            if (!category) {
                category = categoryFromMeta({
                    categoryIndex: categoryIndex,
                    name: rawItem.categoryname
                }, categories.length + 1);
                categories.push(category);
                byIndex[String(category.categoryIndex)] = category;
            }
            category.items.push(normalizeItem(rawItem, index + 1, category));
        });

        return categories.filter(function (category) {
            return category.items.length > 0 || rawCategories.length > 0;
        });
    }

    function getSelectedCategory() {
        return state.categories.find(function (category) {
            return sameIndex(category.categoryIndex, state.selectedCategoryIndex);
        }) || state.categories[0] || null;
    }

    function getVisibleItems() {
        const category = getSelectedCategory();
        if (!category) {
            return [];
        }

        const query = state.search.trim().toLowerCase();
        if (!query) {
            return category.items;
        }

        return category.items.filter(function (item) {
            return [item.label, item.item, item.type].some(function (value) {
                return String(value || "").toLowerCase().includes(query);
            });
        });
    }

    function getSelectedItem() {
        const category = getSelectedCategory();
        if (!category) {
            return null;
        }

        return category.items.find(function (item) {
            return sameIndex(item.itemIndex, state.selectedItemIndex);
        }) || category.items[0] || null;
    }

    function getSelectedRecipes() {
        const item = getSelectedItem();
        return item ? item.recipes : [];
    }

    function getSelectedRecipe() {
        const recipes = getSelectedRecipes();
        return recipes.find(function (recipe) {
            return sameIndex(recipe.recipeIndex, state.selectedRecipeIndex);
        }) || recipes[0] || null;
    }

    function selectedIdentity() {
        return {
            categoryIndex: numeric(state.selectedCategoryIndex, 1),
            itemIndex: numeric(state.selectedItemIndex, 1),
            recipeIndex: numeric(state.selectedRecipeIndex, 1),
            amount: clampAmount(state.amount),
            number: clampAmount(state.amount)
        };
    }

    function ensureSelection(preferred) {
        const active = preferred || {};
        let category = state.categories.find(function (entry) {
            return sameIndex(entry.categoryIndex, active.categoryIndex ?? active.category);
        }) || state.categories[0] || null;

        if (!category) {
            state.selectedCategoryIndex = 1;
            state.selectedItemIndex = 1;
            state.selectedRecipeIndex = 1;
            return;
        }

        let item = category.items.find(function (entry) {
            return sameIndex(entry.itemIndex, active.itemIndex);
        });

        if (!item) {
            category.items.some(function (entry) {
                const activeRecipe = entry.recipes.find(function (recipe) {
                    return recipe.status === true;
                });
                if (entry.status === true || activeRecipe) {
                    item = entry;
                    if (activeRecipe) {
                        active.recipeIndex = activeRecipe.recipeIndex;
                    }
                    return true;
                }
                return false;
            });
        }

        item = item || category.items[0] || null;
        const recipe = item && (item.recipes.find(function (entry) {
            return sameIndex(entry.recipeIndex, active.recipeIndex);
        }) || item.recipes.find(function (entry) {
            return entry.status === true;
        }) || item.recipes[0]);

        state.selectedCategoryIndex = category.categoryIndex;
        state.selectedItemIndex = item ? item.itemIndex : 1;
        state.selectedRecipeIndex = recipe ? recipe.recipeIndex : 1;
    }

    function clampAmount(value) {
        if (isWeapon(getSelectedItem(), getSelectedRecipe())) {
            return 1;
        }
        const amount = Math.floor(numeric(value, 1));
        return Math.max(1, Math.min(100, amount));
    }

    function setAmount(value, shouldPost) {
        state.amount = clampAmount(value);
        renderAmountControls();
        renderRequirements();
        if (shouldPost) {
            postNui("SetCount", selectedIdentity());
        }
    }

    function selectCategory(categoryIndex) {
        state.selectedCategoryIndex = categoryIndex;
        // เปลี่ยนหมวด -> ล้างสถานะพับกลุ่มเดิม ให้กลุ่มของไอเทมแรกในหมวดใหม่กางเองอัตโนมัติ
        state.expandedGroups = {};
        const category = getSelectedCategory();
        const firstItem = category && category.items[0];
        state.selectedItemIndex = firstItem ? firstItem.itemIndex : 1;
        state.selectedRecipeIndex = firstItem && firstItem.recipes[0] ? firstItem.recipes[0].recipeIndex : 1;
        state.amount = clampAmount(state.amount);
        renderAll();
        postNui("ChooseType", {
            categoryIndex: state.selectedCategoryIndex,
            category: state.selectedCategoryIndex
        });
    }

    function selectItem(itemIndex) {
        state.selectedItemIndex = itemIndex;
        const item = getSelectedItem();
        state.selectedRecipeIndex = item && item.recipes[0] ? item.recipes[0].recipeIndex : 1;
        state.amount = clampAmount(state.amount);
        renderAll();
        postNui("Choose", selectedIdentity());
    }

    function selectRecipe(recipeIndex) {
        state.selectedRecipeIndex = recipeIndex;
        state.amount = clampAmount(state.amount);
        renderAll();
        postNui("Choose", selectedIdentity());
    }

    function showUi() {
        state.visible = true;
        els.app.classList.remove("is-hidden");
        els.app.setAttribute("aria-hidden", "false");
    }

    function hideUi(shouldPost) {
        state.visible = false;
        state.craftLocked = false;
        els.app.classList.add("is-hidden");
        els.app.setAttribute("aria-hidden", "true");
        els.notificationToast.classList.add("is-hidden");
        if (shouldPost) {
            postNui("Close", {});
        }
    }

    function handleOpen(payload) {
        if (payload.image) {
            state.imageBase = normalizeImageBase(payload.image);
        }
        state.mockIcons = payload.mockIcons === true;
        state.expandedGroups = {};
        state.categories = normalizePayload(payload);
        state.tableName = payload.nametable || state.tableName || "Craft Table";
        state.amount = Math.max(1, numeric(payload.number ?? payload.amount, state.amount));
        ensureSelection(payload);
        state.amount = clampAmount(state.amount);
        showUi();
        renderAll();
    }

    function renderAll() {
        renderHeader();
        renderCategories();
        renderItemList();
        renderRecipeVariants();
        renderRequirements();
        renderPreview();
        renderAmountControls();
        renderCraftButton();
    }

    function renderHeader() {
        const item = getSelectedItem();
        els.tableName.textContent = state.tableName || "Craft Table";
        els.categoryTitle.textContent = item ? (item.label || item.item || "Selected Item") : "Select Item";
    }

    function renderCategories() {
        clear(els.categoryList);

        state.categories.forEach(function (category) {
            const button = document.createElement("button");
            button.type = "button";
            button.className = "category-button";
            if (sameIndex(category.categoryIndex, state.selectedCategoryIndex)) {
                button.classList.add("is-active");
            }
            button.textContent = category.name || `Category ${category.categoryIndex}`;
            button.title = button.textContent;
            button.addEventListener("click", function () {
                if (!sameIndex(category.categoryIndex, state.selectedCategoryIndex)) {
                    selectCategory(category.categoryIndex);
                }
            });
            els.categoryList.appendChild(button);
        });
    }

    // ชื่อกลุ่มของไอเทม = คำแรกของ label (เช่น "Mauser Frame"/"Mauser Pistol" -> "Mauser")
    // รองรับ field group ที่ config ส่งมาตรงๆ ก่อน (ถ้ามีในอนาคต) — ตอนนี้ยังไม่มี ใช้ label แทน
    // ไม่ต้องแตะ server: จัดกลุ่มฝั่ง UI ล้วน ปลอดภัยกับ payload เดิม
    function groupKeyOf(item) {
        if (item && item.group) {
            return String(item.group).trim();
        }
        const label = String((item && (item.label || item.item)) || "").trim();
        const firstWord = label.split(/\s+/)[0];
        return firstWord || null;
    }

    function itemRowElement(item) {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "recipe-row";
        if (sameIndex(item.itemIndex, state.selectedItemIndex)) {
            button.classList.add("is-active");
        }
        button.appendChild(createIcon(item.item, item.label, "", item.image));
        const copy = document.createElement("div");
        copy.appendChild(textElement("div", "recipe-name", item.label || item.item || "Unknown Item"));
        copy.appendChild(textElement("div", "recipe-meta", isWeapon(item) ? "WEAPON" : "ITEM"));
        button.appendChild(copy);
        button.addEventListener("click", function () {
            selectItem(item.itemIndex);
        });
        return button;
    }

    function groupElement(key, groupItems) {
        const wrap = document.createElement("div");
        wrap.className = "recipe-group";
        const expanded = state.expandedGroups[key] === true;

        const head = document.createElement("button");
        head.type = "button";
        head.className = "group-head" + (expanded ? " is-open" : "");

        const badge = textElement("div", "group-badge", String(key).trim().charAt(0).toUpperCase());
        head.appendChild(badge);
        head.appendChild(textElement("div", "group-name", key));
        head.appendChild(textElement("div", "group-count", `${groupItems.length} ไอเทม`));
        head.appendChild(textElement("div", "group-chevron", "▾"));
        head.title = key;
        head.addEventListener("click", function () {
            state.expandedGroups[key] = !state.expandedGroups[key];
            renderItemList();
        });
        wrap.appendChild(head);

        if (expanded) {
            const body = document.createElement("div");
            body.className = "group-body";
            groupItems.forEach(function (item) {
                body.appendChild(itemRowElement(item));
            });
            wrap.appendChild(body);
        }
        return wrap;
    }

    function renderItemList() {
        clear(els.recipeList);

        const items = getVisibleItems();
        if (!items.length) {
            els.recipeList.appendChild(emptyState("No craftable items"));
            return;
        }

        // ระหว่างค้นหา -> แสดงแบบแบน (แฟลต) ไม่จัดกลุ่ม เพื่อให้เห็นผลลัพธ์ตรงๆ
        const searching = state.search.trim().length > 0;

        if (!searching) {
            const order = [];
            const groups = {};
            items.forEach(function (item) {
                const key = groupKeyOf(item) || "อื่นๆ";
                if (!groups[key]) {
                    groups[key] = [];
                    order.push(key);
                }
                groups[key].push(item);
            });

            // จัดกลุ่มก็ต่อเมื่อมีประโยชน์จริง: มีอย่างน้อย 1 กลุ่มที่มีสมาชิก >= 2 และมีมากกว่า 1 กลุ่ม
            // (หมวดที่ไอเทมชื่อไม่ซ้ำคำแรกกันเลย เช่น ยา/อาหาร จะตกมาเป็นลิสต์แบนเหมือนเดิม)
            const useGroups = order.length >= 2 && order.some(function (key) {
                return groups[key].length >= 2;
            });

            if (useGroups) {
                const selected = getSelectedItem();
                const selectedKey = selected ? (groupKeyOf(selected) || "อื่นๆ") : null;
                order.forEach(function (key) {
                    if (state.expandedGroups[key] === undefined) {
                        state.expandedGroups[key] = (key === selectedKey);
                    }
                });
                order.forEach(function (key) {
                    els.recipeList.appendChild(groupElement(key, groups[key]));
                });
                return;
            }
        }

        items.forEach(function (item) {
            els.recipeList.appendChild(itemRowElement(item));
        });
    }

    function renderRecipeVariants() {
        clear(els.variantCards);

        const item = getSelectedItem();
        const recipes = getSelectedRecipes();

        // มีสูตรเดียว (หรือไม่มี) -> ไม่โชว์การ์ด แต่ปล่อย container ว่างไว้ในผัง
        // (min-height ใน CSS จองพื้นที่ไว้แล้ว) วงแหวน/ชื่อจะได้ไม่เด้งตอนสลับไอเทม
        if (!item || recipes.length <= 1) {
            return;
        }

        recipes.forEach(function (recipe) {
            const card = document.createElement("button");
            card.type = "button";
            card.className = "variant-card";
            if (sameIndex(recipe.recipeIndex, state.selectedRecipeIndex)) {
                card.classList.add("is-active");
            }
            card.appendChild(createIcon(item.item, recipeLabel(recipe), "", recipe.image || item.image));
            card.appendChild(textElement("div", "variant-name", recipeLabel(recipe)));
            card.title = recipe.description || recipeLabel(recipe);
            card.addEventListener("click", function () {
                selectRecipe(recipe.recipeIndex);
            });
            els.variantCards.appendChild(card);
        });
    }

    function requirementRow(row, options) {
        const chip = document.createElement("div");
        chip.className = "requirement-chip";
        if (options && options.currency) {
            chip.classList.add("is-currency");
        }
        if (options && options.optional) {
            chip.classList.add("is-optional");
        }

        chip.appendChild(createIcon(row.name, row.label));

        const copy = document.createElement("div");
        copy.appendChild(textElement("div", "chip-name", row.label || row.name || "Unknown"));
        if (options && options.subtext) {
            copy.appendChild(textElement("div", "chip-sub", options.subtext));
        }
        chip.appendChild(copy);

        const amount = numeric(row.amox, 0) * (options && options.multiply ? state.amount : 1);
        chip.appendChild(textElement("div", "chip-amount", `x${formatCount(amount)}`));
        return chip;
    }

    function toggleBlock(listEl, show) {
        const block = listEl.closest(".req-block");
        if (block) {
            block.style.display = show ? "" : "none";
        }
    }

    function renderRequirements() {
        const recipe = getSelectedRecipe();
        clear(els.materialsList);
        clear(els.toolsList);
        clear(els.failedList);

        if (!recipe) {
            els.materialsList.appendChild(emptyState("No material data"));
            toggleBlock(els.materialsList, true);
            toggleBlock(els.toolsList, false);
            toggleBlock(els.failedList, false);
            return;
        }

        const materials = (recipe.cost || []).concat(recipe.blueprint || []);
        // บล็อกวัตถุดิบแสดงเสมอ (เป็นข้อมูลหลักของทุกสูตร)
        toggleBlock(els.materialsList, true);
        if (!materials.length) {
            els.materialsList.appendChild(emptyState("No materials required"));
        } else {
            materials.forEach(function (row) {
                const isCurrency = ["money", "gold", "rol"].includes(String(row.name || "").toLowerCase());
                els.materialsList.appendChild(requirementRow(row, {
                    currency: isCurrency,
                    multiply: true,
                    subtext: isCurrency ? "Cost" : "Material"
                }));
            });
        }

        // ไอเทมที่ต้องมี / ได้รับเมื่อไม่สำเร็จ -> โชว์เฉพาะเมื่อสูตรนี้มีจริง (ตามที่ผู้เล่นขอ)
        const tools = recipe.toolsList || [];
        toggleBlock(els.toolsList, tools.length > 0);
        tools.forEach(function (row) {
            els.toolsList.appendChild(requirementRow(row, {
                optional: row.status === false,
                multiply: false,
                subtext: row.status === false ? "Optional" : "Required"
            }));
        });

        const failed = recipe.failedList || [];
        toggleBlock(els.failedList, failed.length > 0);
        if (failed.length) {
            failed.forEach(function (row) {
                els.failedList.appendChild(requirementRow(row, {
                    multiply: false,
                    subtext: "Possible return"
                }));
            });
            const chance = numeric(recipe.custom_percent_failitem, 0);
            if (chance > 0) {
                els.failedList.appendChild(textElement("div", "chip-sub", `Return chance ${formatCount(chance)}%`));
            }
        }
    }

    function renderPreview() {
        const item = getSelectedItem();
        const recipe = getSelectedRecipe();
        clear(els.previewIcon);

        if (!item) {
            els.previewIcon.appendChild(createIcon("", "?"));
            els.previewMeta.textContent = "ITEM";
            els.previewName.textContent = "Select Item";
            els.previewChance.textContent = "";
            return;
        }

        const previewLabel = recipe && (recipe.previewLabel || recipe.itemLabel) || item.label || item.item;
        els.previewIcon.appendChild(createIcon(item.item, previewLabel, "", recipe && recipe.image || item.image));
        els.previewMeta.textContent = isWeapon(item, recipe) ? "WEAPON" : "ITEM";
        els.previewName.textContent = previewLabel || item.item || "Unknown Item";
        const successRate = numeric(recipe && recipe.success_rate, null);
        const failChance = numeric(recipe && recipe.fail_chance, null);
        if (successRate !== null) {
            els.previewChance.textContent = `Success ${formatCount(successRate)}%`;
        } else if (failChance !== null) {
            els.previewChance.textContent = `Fail ${formatCount(failChance)}%`;
        } else {
            els.previewChance.textContent = "";
        }
    }

    function renderAmountControls() {
        const item = getSelectedItem();
        const recipe = getSelectedRecipe();
        const locked = isWeapon(item, recipe);
        if (locked) {
            state.amount = 1;
        }
        els.amountInput.value = String(clampAmount(state.amount));
        els.amountInput.disabled = locked || !recipe;
        els.amountMinus.disabled = locked || !recipe;
        els.amountPlus.disabled = locked || !recipe;
    }

    function renderCraftButton() {
        els.craftButton.disabled = !getSelectedRecipe() || state.craftLocked;
    }

    function showNotification(text) {
        els.notificationText.textContent = text || "";
        if (state.visible) {
            els.notificationToast.classList.remove("is-hidden");
        }
    }

    function handleSound(payload) {
        if (!payload.transactionFile) {
            return;
        }

        if (state.activeAudio) {
            state.activeAudio.pause();
            state.activeAudio = null;
        }

        const audio = new Audio(`./sounds/${payload.transactionFile}.mp3`);
        audio.volume = Math.max(0, Math.min(1, numeric(payload.transactionVolume, 0.5)));
        state.activeAudio = audio;
        audio.play().catch(function () {});

        if (payload.transactionType === "playSoundFlash") {
            const hold = numeric(payload.transactionHold, 0);
            const stepTime = numeric(payload.transactionTime, 80);
            window.setTimeout(function () {
                const fade = window.setInterval(function () {
                    if (!state.activeAudio || state.activeAudio.volume <= 0.05) {
                        window.clearInterval(fade);
                        return;
                    }
                    state.activeAudio.volume = Math.max(0, state.activeAudio.volume - 0.04);
                }, stepTime);
            }, hold);
        }
    }

    window.addEventListener("message", function (event) {
        const payload = event.data || {};

        if (payload.image) {
            state.imageBase = normalizeImageBase(payload.image);
        }

        if (payload.notification === "notification") {
            showNotification(payload.text);
        }

        if (payload.acton === "openmenu") {
            handleOpen(payload);
        } else if (payload.acton === "closemenus") {
            hideUi(false);
        } else if (payload.acton === "Sound") {
            handleSound(payload);
        }
    });

    els.searchInput.addEventListener("input", function () {
        state.search = els.searchInput.value || "";
        renderItemList();
    });

    els.amountMinus.addEventListener("click", function () {
        setAmount(state.amount - 1, true);
    });

    els.amountPlus.addEventListener("click", function () {
        setAmount(state.amount + 1, true);
    });

    els.amountInput.addEventListener("change", function () {
        setAmount(els.amountInput.value, true);
    });

    els.amountInput.addEventListener("keydown", function (event) {
        if (event.key === "Enter") {
            event.preventDefault();
            setAmount(els.amountInput.value, true);
            els.amountInput.blur();
        }
    });

    els.craftButton.addEventListener("click", function () {
        const recipe = getSelectedRecipe();
        if (!recipe || state.craftLocked) {
            return;
        }
        state.craftLocked = true;
        renderCraftButton();
        postNui("Crafting", selectedIdentity());
        window.setTimeout(function () {
            state.craftLocked = false;
            renderCraftButton();
        }, 1400);
    });

    els.closeButton.addEventListener("click", function () {
        hideUi(true);
    });

    els.notificationClose.addEventListener("click", function () {
        els.notificationToast.classList.add("is-hidden");
    });

    document.addEventListener("keyup", function (event) {
        if (event.key === "Escape" && state.visible) {
            hideUi(true);
        }
    });

    function mockPayload() {
        const position = { x: -368.72, y: 795.92, z: 116.28, h: 28.44 };

        return {
            acton: "openmenu",
            mockIcons: true,
            nametable: "Valentine Craft Table",
            number: 1,
            categoryIndex: 1,
            itemIndex: 1,
            recipeIndex: 1,
            datatype: [
                { Category: 1, categoryname: "Weapons" },
                { Category: 5, categoryname: "อาวุธ Tier 1" },
                { Category: 2, categoryname: "Medicine" },
                { Category: 3, categoryname: "Food" },
                { Category: 4, categoryname: "Materials" }
            ],
            data: [
                {
                    Category: 1,
                    categoryname: "Weapons",
                    position: position,
                    id: 1,
                    itemIndex: 1,
                    type: "item_weapon",
                    item: "WEAPON_REVOLVER_NAVY",
                    label: "Navy Revolver",
                    status: true,
                    recipes: [
                        {
                            recipeIndex: 1,
                            label: "Cheap Recipe",
                            description: "Uses fewer parts with a higher failure chance",
                            fail_chance: 20,
                            success_rate: 80,
                            max_stack: 2,
                            cost: [{ name: "Money", amox: 50, label: "Cash" }],
                            blueprint: [
                                { name: "iron", amox: 10, label: "Iron" },
                                { name: "wood", amox: 4, label: "Wood" },
                                { name: "mechanism", amox: 1, label: "Mechanism" }
                            ],
                            toolsList: [{ name: "hammer", amox: 1, status: true, label: "Hammer" }],
                            failedList: [{ name: "iron", amox: 2, label: "Iron" }],
                            status: true
                        },
                        {
                            recipeIndex: 2,
                            label: "Standard Recipe",
                            description: "Costs more materials with better success",
                            fail_chance: 10,
                            success_rate: 90,
                            max_stack: 2,
                            cost: [{ name: "Money", amox: 100, label: "Cash" }],
                            blueprint: [
                                { name: "iron", amox: 20, label: "Iron" },
                                { name: "wood", amox: 8, label: "Wood" },
                                { name: "mechanism", amox: 2, label: "Mechanism" }
                            ],
                            toolsList: [
                                { name: "hammer", amox: 1, status: true, label: "Hammer" },
                                { name: "weapon_blueprint", amox: 1, status: true, label: "Weapon Blueprint" }
                            ],
                            failedList: [
                                { name: "iron", amox: 4, label: "Iron" },
                                { name: "mechanism", amox: 1, label: "Mechanism" }
                            ],
                            status: false
                        }
                    ]
                },
                {
                    Category: 1,
                    categoryname: "Weapons",
                    position: position,
                    id: 2,
                    itemIndex: 2,
                    type: "item_weapon",
                    item: "WEAPON_REVOLVER_SCHOFIELD",
                    label: "Schofield Revolver",
                    recipes: [
                        {
                            recipeIndex: 1,
                            label: "Recipe 1",
                            fail_chance: 0,
                            success_rate: 100,
                            max_stack: 50,
                            cost: [{ name: "Money", amox: 10, label: "Cash" }],
                            blueprint: [
                                { name: "gunpowder", amox: 5, label: "Gunpowder" },
                                { name: "shell", amox: 5, label: "Shell" }
                            ]
                        }
                    ]
                },
                mockPart(5, 1, "part_mauser_frame", "Mauser Frame", 60, [
                    { name: "loot_necklace", amox: 7 }, { name: "loot_ring", amox: 10 },
                    { name: "mat_diamond", amox: 5 }, { name: "mat_iron", amox: 10 }, { name: "misc_toolbox", amox: 1 }
                ]),
                mockPart(5, 2, "part_mauser_barrel", "Mauser Barrel", 70, [
                    { name: "loot_silver_tooth", amox: 6 }, { name: "mat_ruby", amox: 5 },
                    { name: "mat_copper", amox: 10 }, { name: "misc_toolbox", amox: 1 }
                ]),
                mockPart(5, 3, "part_mauser_stock", "Mauser Stock", 60, [
                    { name: "loot_earring", amox: 7 }, { name: "mat_emerald", amox: 5 },
                    { name: "met_wood_planks", amox: 10 }, { name: "misc_toolbox", amox: 1 }
                ]),
                mockPart(5, 4, "part_mauser_molds", "Mauser Molds", 60, [
                    { name: "blueprint_low", amox: 5 }
                ]),
                {
                    Category: 5,
                    categoryname: "อาวุธ Tier 1",
                    position: position,
                    id: 5,
                    itemIndex: 5,
                    type: "item_weapon",
                    item: "WEAPON_PISTOL_MAUSER",
                    label: "Mauser Pistol",
                    recipes: [
                        {
                            recipeIndex: 1,
                            label: "Mauser Pistol",
                            fail_chance: 0,
                            success_rate: 100,
                            max_stack: 1,
                            blueprint: [
                                { name: "part_mauser_frame", amox: 1 }, { name: "part_mauser_barrel", amox: 1 },
                                { name: "part_mauser_stock", amox: 1 }, { name: "part_mauser_molds", amox: 1 },
                                { name: "misc_toolbox", amox: 1 }
                            ],
                            toolsList: [{ name: "misc_toolbox", amox: 1, status: true, label: "กล่องเครื่องมือ" }]
                        }
                    ]
                },
                mockPart(5, 6, "part_schofield_frame", "Schofield Frame", 60, [
                    { name: "mat_iron", amox: 8 }, { name: "misc_toolbox", amox: 1 }
                ]),
                mockPart(5, 7, "part_schofield_barrel", "Schofield Barrel", 70, [
                    { name: "mat_copper", amox: 8 }, { name: "misc_toolbox", amox: 1 }
                ])
            ]
        };
    }

    function mockPart(category, index, itemName, label, successRate, blueprint) {
        return {
            Category: category,
            categoryname: "อาวุธ Tier 1",
            id: index,
            itemIndex: index,
            type: "item_standard",
            item: itemName,
            label: label,
            recipes: [
                {
                    recipeIndex: 1,
                    label: label,
                    fail_chance: 100 - successRate,
                    success_rate: successRate,
                    max_stack: 1,
                    blueprint: blueprint.map(function (b) {
                        return { name: b.name, amox: b.amox, label: b.name };
                    })
                }
            ]
        };
    }

    function openMockMenu() {
        handleOpen(mockPayload());
    }

    if (isBrowserPreview) {
        window.nxCraftingMock = {
            open: openMockMenu,
            notify: showNotification,
            payload: mockPayload
        };
        window.setTimeout(openMockMenu, 0);
    }
})();
