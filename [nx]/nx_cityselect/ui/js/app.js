/* ─────────────────────────────────────────────────
   app.js — nx_cityselect UI Logic
   No frameworks, no build step, pure ES6+
───────────────────────────────────────────────── */

const App = (() => {
    'use strict';

    // ── State ──────────────────────────────────────
    let cities          = [];
    let lang            = {};
    let pendingCityId   = null;

    // ── DOM refs (resolved once) ───────────────────
    const dom = {};

    function resolveDOM() {
        dom.app          = document.getElementById('app');
        dom.citiesRow    = document.getElementById('cities-row');
        dom.titleEl      = document.getElementById('ui-title');
        dom.subtitleEl   = document.getElementById('ui-subtitle');
        dom.modal        = document.getElementById('confirm-modal');
        dom.modalTitle   = document.getElementById('modal-title');
        dom.modalMsg     = document.getElementById('modal-msg');
        dom.btnConfirm   = document.getElementById('btn-confirm');
        dom.btnCancel    = document.getElementById('btn-cancel');
        dom.territoryHud = document.getElementById('territory-hud');
        dom.territoryPip = document.getElementById('territory-pip');
        dom.territoryName= document.getElementById('territory-name');
    }

    // ── City icons (SVG inline, one per city by index) ──
    const ICONS = [
        // Cowboy hat
        `<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" width="38" height="38">
          <ellipse cx="24" cy="34" rx="20" ry="6" fill="#8b4513" opacity=".9"/>
          <path d="M10 34 Q14 18 24 16 Q34 18 38 34Z" fill="#a0522d"/>
          <rect x="16" y="21" width="16" height="3" rx="1.5" fill="#c8900a" opacity=".8"/>
        </svg>`,
        // Anchor / ship wheel
        `<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" width="38" height="38">
          <circle cx="24" cy="14" r="5" stroke="#8b4513" stroke-width="2.5" fill="none"/>
          <line x1="24" y1="19" x2="24" y2="40" stroke="#8b4513" stroke-width="2.5"/>
          <path d="M14 36 Q18 42 24 40 Q30 42 34 36" stroke="#8b4513" stroke-width="2.5" fill="none"/>
          <line x1="14" y1="26" x2="34" y2="26" stroke="#8b4513" stroke-width="2"/>
        </svg>`,
        // Rose / magnolia
        `<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" width="38" height="38">
          <circle cx="24" cy="22" r="8" fill="#c8900a" opacity=".85"/>
          <path d="M24 14 Q28 10 32 14 Q36 18 32 22 Q28 26 24 22Z" fill="#a0522d" opacity=".7"/>
          <path d="M24 14 Q20 10 16 14 Q12 18 16 22 Q20 26 24 22Z" fill="#a0522d" opacity=".7"/>
          <path d="M16 22 Q12 26 16 30 Q20 34 24 30Z" fill="#8b4513" opacity=".6"/>
          <path d="M32 22 Q36 26 32 30 Q28 34 24 30Z" fill="#8b4513" opacity=".6"/>
          <line x1="24" y1="30" x2="24" y2="44" stroke="#5c2e0a" stroke-width="2"/>
        </svg>`,
    ];

    // ── Helpers ────────────────────────────────────

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

    function rgbStr({ r, g, b, a = 1 }) {
        return `rgba(${r},${g},${b},${a / (a > 1 ? 255 : 1)})`;
    }

    function postNUI(action, data = {}) {
        return fetch(`https://nx_cityselect/${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data),
        }).then(r => r.json()).catch(() => null);
    }

    // ── Render city cards ──────────────────────────

    function renderCities(cityList) {
        dom.citiesRow.innerHTML = '';
        cityList.forEach((city, i) => {
            const pct       = clamp((city.count / city.max) * 100, 0, 100);
            const isFull    = !city.available;
            const iconSVG   = ICONS[i % ICONS.length];
            const colorStr  = rgbStr(city.color);
            const tabIndex  = isFull ? -1 : 0;

            const card = document.createElement('div');
            card.className  = `city-card${isFull ? ' disabled' : ''}`;
            card.dataset.id = city.id;
            card.setAttribute('role', 'button');
            card.setAttribute('tabindex', String(tabIndex));
            card.setAttribute('aria-label', `${city.name} — ${isFull ? lang.fullLabel : lang.selectBtn}`);

            card.innerHTML = `
                <span class="card-banner" style="background:${colorStr}"></span>
                <div class="city-icon-wrap">
                    <div class="city-icon">${iconSVG}</div>
                </div>
                <div class="card-body">
                    <div class="city-name">${city.name}</div>
                    <div class="city-label">${city.label}</div>
                    <hr class="card-divider"/>
                    <p class="city-desc">${city.description}</p>
                    <div class="slot-row">
                        <span class="slot-pip ${isFull ? 'full' : ''}"></span>
                        <span class="slot-text">${lang.slotsLabel}: ${city.count} / ${city.max}</span>
                    </div>
                </div>
                <div class="slot-bar-track">
                    <div class="slot-bar-fill ${isFull ? 'full' : ''}"
                         style="width:${pct}%"></div>
                </div>
                ${!isFull ? `<button class="btn-select" tabindex="${tabIndex}">${lang.selectBtn}</button>` : ''}
                ${isFull  ? `<div class="full-stamp">${lang.fullLabel}</div>` : ''}
            `;

            if (!isFull) {
                card.addEventListener('click', () => openConfirm(city));
                card.addEventListener('keydown', e => {
                    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openConfirm(city); }
                });
            }

            dom.citiesRow.appendChild(card);
        });
    }

    // ── Open confirm modal ─────────────────────────

    function openConfirm(city) {
        pendingCityId = city.id;
        const msg = (lang.confirmMsg || 'คุณแน่ใจหรือไม่?').replace('%s', city.name);
        dom.modalTitle.textContent = lang.confirmTitle || 'ยืนยัน';
        dom.modalMsg.textContent   = msg;
        dom.modal.classList.remove('hidden');
    }

    function closeConfirm() {
        pendingCityId = null;
        dom.modal.classList.add('hidden');
    }

    // ── Submit selection to Lua ────────────────────

    function submitCity(cityId) {
        if (!cityId) return;
        dom.modal.classList.add('hidden');
        // Disable all cards while awaiting server
        dom.citiesRow.querySelectorAll('.city-card').forEach(c => {
            c.classList.add('disabled');
            c.setAttribute('tabindex', '-1');
        });
        postNUI('selectCity', { cityId });
    }

    // ── Territory HUD update ───────────────────────

    function setTerritory(zoneName, color, isOwnCity) {
        if (!zoneName) {
            dom.territoryHud.classList.add('hidden');
            return;
        }
        const c = color || { r: 200, g: 144, b: 10, a: 255 };
        dom.territoryPip.style.backgroundColor = `rgb(${c.r},${c.g},${c.b})`;
        dom.territoryPip.style.color           = `rgb(${c.r},${c.g},${c.b})`;
        dom.territoryName.textContent           = zoneName;
        dom.territoryHud.classList.remove('hidden');
    }

    // ── NUI message handler ────────────────────────

    window.addEventListener('message', ({ data }) => {
        if (!data || !data.action) return;

        switch (data.action) {
            case 'OPEN': {
                if (data.lang)  lang   = data.lang;
                if (data.cities) cities = data.cities;

                if (dom.titleEl)    dom.titleEl.textContent    = lang.title    || 'เลือกเมือง';
                if (dom.subtitleEl) dom.subtitleEl.textContent = lang.subtitle || '';

                renderCities(cities);
                dom.app.classList.remove('hidden');
                // Focus first available card for keyboard nav
                const firstCard = dom.citiesRow.querySelector('.city-card:not(.disabled)');
                if (firstCard) setTimeout(() => firstCard.focus(), 300);
                break;
            }

            case 'CLOSE': {
                dom.app.classList.add('hidden');
                closeConfirm();
                break;
            }

            case 'SET_TERRITORY': {
                setTerritory(data.zoneName, data.color, data.isOwnCity);
                break;
            }
        }
    });

    // ── Confirm modal button wiring ────────────────

    function init() {
        resolveDOM();

        dom.btnConfirm.addEventListener('click', () => {
            if (pendingCityId) submitCity(pendingCityId);
        });

        dom.btnCancel.addEventListener('click', closeConfirm);

        // ESC key: close confirm modal only; cannot close main UI
        document.addEventListener('keydown', e => {
            if (e.key === 'Escape' && !dom.modal.classList.contains('hidden')) {
                closeConfirm();
            }
        });
    }

    document.addEventListener('DOMContentLoaded', init);

})();
