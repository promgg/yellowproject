(() => {
    'use strict';

    const ICONS = {
        mic: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3a4 4 0 0 0-4 4v5a4 4 0 0 0 8 0V7a4 4 0 0 0-4-4Zm7 8.2a1 1 0 0 0-2 0A5 5 0 0 1 7 11.2a1 1 0 0 0-2 0A7 7 0 0 0 11 18.9V21H8a1 1 0 1 0 0 2h8a1 1 0 1 0 0-2h-3v-2.1a7 7 0 0 0 6-6.7Z"/></svg>',
        speaker: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 9v6h4l6 5V4L8 9H4Zm13.2-3.3a1 1 0 0 0-1.4 1.4 7 7 0 0 1 0 9.8 1 1 0 0 0 1.4 1.4 9 9 0 0 0 0-12.6Z"/></svg>',
        heart: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 21s-8.5-5.2-10.6-11A5.5 5.5 0 0 1 11 4.3l1 1.1 1-1.1A5.5 5.5 0 0 1 22.6 10C20.5 15.8 12 21 12 21Z"/></svg>',
        heartPulse: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 21s-8.5-5.2-10.6-11A5.5 5.5 0 0 1 11 4.3l1 1.1 1-1.1A5.5 5.5 0 0 1 22.6 10c-.3.9-.8 1.8-1.4 2.6h-4.1l-1.9-4.1-3.1 7-2.2-4.1H5.8c-.6-.8-1.1-1.7-1.4-2.5h4.8l2.5 4.7 3.2-7.2 2.4 5.2h4.3C18.7 16.2 12 21 12 21Z"/></svg>',
        food: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M16.3 3.2a6.2 6.2 0 0 0-6.7 1.3A6.7 6.7 0 0 0 7.8 11l-5.2 5.2a2.1 2.1 0 0 0 0 3l1.2 1.2a2.1 2.1 0 0 0 3 0l5.2-5.2a6.7 6.7 0 0 0 6.5-1.8 6.2 6.2 0 0 0 1.3-6.7 2.6 2.6 0 1 0-3.5-3.5Z"/></svg>',
        water: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2S5 10.2 5 15a7 7 0 0 0 14 0c0-4.8-7-13-7-13Zm0 17a4 4 0 0 1-4-4 1 1 0 0 1 2 0 2 2 0 0 0 2 2 1 1 0 1 1 0 2Z"/></svg>',
        core: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 3a4 4 0 0 0-4 4v.5A4.5 4.5 0 0 0 3 15a4 4 0 0 0 4 4h2V3Zm6 0v16h2a4 4 0 0 0 4-4 4.5 4.5 0 0 0-2-7.5V7a4 4 0 0 0-4-4Zm-3 2h2v14h-2V5Z"/></svg>',
        bolt: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M13 2 4 14h7l-2 8 11-14h-7l2-6Z"/></svg>',
        saddle: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 7h6a5 5 0 0 1 5 5v1h3a2 2 0 0 1 2 2v3h-4v-2h-6v2H7v-2H3v-5a4 4 0 0 1 2-3.5V7Zm2 3a2 2 0 0 0-2 2v1h5.8A7 7 0 0 0 7 10Z"/></svg>'
    };

    const DEFAULT_STATUS_ICONS = [
        { key: 'food', icon: 'food' },
        { key: 'water', icon: 'water' },
        { key: 'core', icon: 'core' }
    ];

    const state = {
        visible: true,
        secondaryEnabled: true,
        statusIcons: DEFAULT_STATUS_ICONS,
        horseVisible: false
    };

    const els = {
        root: document.getElementById('nxHudRoot'),
        playerId: document.getElementById('nxPlayerId'),
        micBox: document.getElementById('nxMicBox'),
        voiceMode: document.getElementById('nxVoiceMode'),
        healthRow: document.querySelector('.nx-health-row'),
        healthFill: document.getElementById('nxHealthFill'),
        secondaryBar: document.getElementById('nxSecondaryBar'),
        secondaryFill: document.getElementById('nxSecondaryFill'),
        statusIcons: document.getElementById('nxStatusIcons'),
        horsePanel: document.getElementById('nxHorsePanel'),
        horseRows: {
            condition: document.querySelector('[data-horse-key="condition"]')
        },
        horseBars: {
            health: document.getElementById('nxHorseHealthFill'),
            stamina: document.getElementById('nxHorseStaminaFill'),
            condition: document.getElementById('nxHorseConditionFill')
        }
    };

    const statusNodes = new Map();

    function isObject(value) {
        return value !== null && typeof value === 'object' && !Array.isArray(value);
    }

    function clampPercent(value, fallback = 0) {
        const number = Number(value);

        if (!Number.isFinite(number)) {
            return fallback;
        }

        return Math.max(0, Math.min(100, number));
    }

    function boolFromPayload(value) {
        return value === true || value === 1 || value === 'true';
    }

    function cleanText(value, fallback) {
        if (value === null || value === undefined || value === '') {
            return fallback;
        }

        return String(value);
    }

    function setText(el, value) {
        if (el && el.textContent !== value) {
            el.textContent = value;
        }
    }

    function iconName(name, fallback = 'core') {
        const key = cleanText(name, fallback);
        return Object.prototype.hasOwnProperty.call(ICONS, key) ? key : fallback;
    }

    function setIcon(el, name) {
        if (!el) {
            return;
        }

        const key = iconName(name);

        if (el.dataset.currentIcon === key) {
            return;
        }

        el.dataset.currentIcon = key;
        el.innerHTML = ICONS[key];
    }

    function setBar(el, value) {
        if (!el) {
            return;
        }

        el.style.width = `${clampPercent(value)}%`;
    }

    function cssLength(value, fallback) {
        if (typeof value === 'number' && Number.isFinite(value)) {
            return `${value}px`;
        }

        if (typeof value === 'string') {
            const trimmed = value.trim();

            if (/^-?\d+(\.\d+)?$/.test(trimmed)) {
                return `${trimmed}px`;
            }

            if (/^-?\d+(\.\d+)?(px|%|vh|vw|rem|em)$/.test(trimmed)) {
                return trimmed;
            }
        }

        return fallback;
    }

    function applyLayout(layout) {
        if (!isObject(layout)) {
            return;
        }

        const docStyle = document.documentElement.style;
        const scale = Number(layout.Scale);

        if (Number.isFinite(scale) && scale > 0) {
            docStyle.setProperty('--hud-scale', String(Math.max(0.6, Math.min(1.4, scale))));
        }

        if (isObject(layout.Main)) {
            const main = layout.Main;
            const anchor = cleanText(main.Anchor, 'bottom-left');

            if (els.root) {
                els.root.dataset.anchor = anchor === 'top-left' ? 'top-left' : 'bottom-left';
            }

            docStyle.setProperty('--hud-left', cssLength(main.Left, '24px'));
            docStyle.setProperty('--hud-top', cssLength(main.Top, '24px'));
            docStyle.setProperty('--hud-bottom', cssLength(main.Bottom, '28px'));
        }

        if (isObject(layout.Horse)) {
            docStyle.setProperty('--horse-left', cssLength(layout.Horse.Left, '642px'));
            docStyle.setProperty('--horse-top', cssLength(layout.Horse.Top, '45px'));
        }
    }

    function hydrateStaticIcons() {
        document.querySelectorAll('[data-icon]').forEach((el) => {
            setIcon(el, el.dataset.icon);
        });
    }

    function normalizeStatusMeta(items) {
        if (!Array.isArray(items)) {
            if (isObject(items) && Object.keys(items).length === 0) {
                return [];
            }

            return DEFAULT_STATUS_ICONS;
        }

        return items
            .filter((item) => isObject(item) && item.key)
            .slice(0, 3)
            .map((item) => ({
                key: cleanText(item.key, 'core'),
                icon: iconName(item.icon || item.key)
            }));
    }

    function createStatusNode(item) {
        const node = document.createElement('div');
        node.className = 'nx-status-icon';
        node.dataset.statusKey = item.key;
        node.style.setProperty('--value', '100%');

        const icon = document.createElement('span');
        icon.className = 'nx-svg-icon';
        node.appendChild(icon);
        setIcon(icon, item.icon);

        return node;
    }

    function renderStatusIcons(items) {
        if (!els.statusIcons) {
            return;
        }

        statusNodes.clear();
        els.statusIcons.innerHTML = '';
        state.statusIcons = normalizeStatusMeta(items);

        state.statusIcons.forEach((item) => {
            const node = createStatusNode(item);
            statusNodes.set(item.key, node);
            els.statusIcons.appendChild(node);
        });
    }

    function statusListFromPayload(icons) {
        if (Array.isArray(icons)) {
            return icons.filter((item) => isObject(item) && item.key);
        }

        if (isObject(icons)) {
            return Object.keys(icons).map((key) => ({
                key,
                value: icons[key]
            }));
        }

        return [];
    }

    function ensureStatusNode(item) {
        const key = cleanText(item.key, '');

        if (!key) {
            return null;
        }

        if (statusNodes.has(key)) {
            return statusNodes.get(key);
        }

        const node = createStatusNode({
            key,
            icon: iconName(item.icon || key)
        });

        statusNodes.set(key, node);

        if (els.statusIcons && statusNodes.size <= 3) {
            els.statusIcons.appendChild(node);
        }

        return node;
    }

    function updateStatusIcons(icons) {
        statusListFromPayload(icons).slice(0, 3).forEach((item) => {
            const node = ensureStatusNode(item);

            if (!node) {
                return;
            }

            if (item.icon) {
                setIcon(node.querySelector('.nx-svg-icon'), item.icon);
            }

            const missing = item.value === null || item.value === undefined;
            const value = clampPercent(item.value, 0);

            node.style.setProperty('--value', `${value}%`);
            node.classList.toggle('is-muted', missing);
            node.classList.toggle('is-warning', !missing && value <= 35 && value > 15);
            node.classList.toggle('is-critical', !missing && value <= 15);
        });
    }

    function setHudVisible(visible) {
        state.visible = visible;

        if (els.root) {
            els.root.classList.toggle('is-visible', visible);
        }
    }

    function setHorseVisible(visible) {
        state.horseVisible = visible;

        if (els.horsePanel) {
            els.horsePanel.classList.toggle('is-visible', visible);
            els.horsePanel.setAttribute('aria-hidden', visible ? 'false' : 'true');
        }
    }

    function updateHud(data) {
        const player = isObject(data.player) ? data.player : {};
        const voice = isObject(data.voice) ? data.voice : {};
        const status = isObject(data.status) ? data.status : {};

        if (player.id !== undefined && player.id !== null) {
            setText(els.playerId, `ID: ${cleanText(player.id, '--')}`);
        }

        if (voice.mode !== undefined) {
            setText(els.voiceMode, cleanText(voice.mode, 'NORMAL').toUpperCase().slice(0, 10));
        }

        if (els.micBox && voice.talking !== undefined) {
            els.micBox.classList.toggle('is-talking', boolFromPayload(voice.talking));
        }

        if (status.health !== undefined) {
            const health = clampPercent(status.health);
            setBar(els.healthFill, health);

            if (els.healthRow) {
                els.healthRow.classList.toggle('is-low', health <= 25);
                els.healthRow.classList.toggle('is-critical', health <= 10);
            }
        }

        if (els.secondaryBar) {
            const hasSecondary = state.secondaryEnabled && status.secondary !== null && status.secondary !== undefined;
            els.secondaryBar.classList.toggle('is-hidden', !hasSecondary);

            if (hasSecondary) {
                setBar(els.secondaryFill, status.secondary);
            }
        }

        if (status.icons !== undefined) {
            updateStatusIcons(status.icons);
        }
    }

    function updateHorse(data) {
        const horse = isObject(data.horse) ? data.horse : data;

        if (!isObject(horse)) {
            return;
        }

        if (horse.mounted !== undefined) {
            setHorseVisible(boolFromPayload(horse.mounted));
        }

        if (horse.health !== undefined) {
            setBar(els.horseBars.health, horse.health);
        }

        if (horse.stamina !== undefined) {
            setBar(els.horseBars.stamina, horse.stamina);
        }

        const hasCondition = horse.condition !== null && horse.condition !== undefined;

        if (els.horseRows.condition) {
            els.horseRows.condition.classList.toggle('is-hidden', !hasCondition);
        }

        if (hasCondition) {
            setBar(els.horseBars.condition, horse.condition);
        }
    }

    function applyConfig(data) {
        applyLayout(data.layout);

        if (isObject(data.secondaryBar) && data.secondaryBar.enabled !== undefined) {
            state.secondaryEnabled = boolFromPayload(data.secondaryBar.enabled);
            if (els.secondaryBar) {
                els.secondaryBar.classList.toggle('is-hidden', !state.secondaryEnabled);
            }
        }

        if (data.statusIcons !== undefined) {
            renderStatusIcons(data.statusIcons);
        }
    }

    window.addEventListener('message', (event) => {
        const data = event && event.data;

        if (!isObject(data) || !data.action) {
            return;
        }

        switch (data.action) {
            case 'hud:config':
                applyConfig(data);
                break;
            case 'hud:setVisible':
                setHudVisible(boolFromPayload(data.visible !== undefined ? data.visible : data.show));
                break;
            case 'hud:update':
                updateHud(data);
                break;
            case 'horse:setVisible':
                setHorseVisible(boolFromPayload(data.visible !== undefined ? data.visible : data.show));
                break;
            case 'horse:update':
                updateHorse(data);
                break;
            default:
                break;
        }
    });

    hydrateStaticIcons();
    renderStatusIcons(DEFAULT_STATUS_ICONS);
    setHudVisible(true);
    setHorseVisible(false);
})();
