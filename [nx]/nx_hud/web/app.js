(() => {
    'use strict';

    const FIGMA_BRAIN = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFoAAABaCAYAAAA4qEECAAAACXBIWXMAAAsTAAALEwEAmpwYAAAFFElEQVR4nO2cz69dUxTHt/pRlKAjr0j6S/wPgoGS4CUG6A9jI+pHYvAIRSeSMuoPiTLyIyEGUqQzKg2ifXm0DPyYiIn7qiit27TvafnI6t0vuZd79z3n3LX22fe8/Uk66MvNXt/1zT7nrLP3Otu5TCaTyWQymUwmk8n0B7gYeAyYBk76fweBR4GlscdpJMC1wNcM5iv5TaxxGgmdGRgyp9ukpdbjNBY6l3lRHrEep7HQuZcW5YD1OI0FaJcwqG09zlgDXA6sB94EvgRmgXmgRUkCMcrS8hpmvaY3gPuAy9y4AVwFvAicqmBEXwKxtBCtLwBXunHAz+BjKOMGx9NGtN/rUgU4D3gO+McgeQJxLZAcnpWcXGoAWzHEDY5ryTMuJfzDxGQmLxCIbYnkdI9LAXl4WNyT/0sgvjW/A8vjuto/UakuzHGD48dgW1xX+9fJaiVciICGGJyqtc4GNkRK9ITSm+Eo1Ffy+Te+GHwb0PB9JA2vx3W3N8lDkZJ8OaDh1UgaZuK625ukrBfE4NaAhtsiaWjFdbc3SVmcsWZfAR37I+iYj+Nq/wSPGid3DFhbQMcq4FdjLbNxXO2foCwzWvEbcFMJLTcbvzh9YetmOLmXjJLaB6ypoGct8LGRpl02LsZdSGoD3wC7Qw++ErrWAa9IWahYZ2/Vca1cIucrzOY5YApYEUHvCuAJhYf3TsndWu+C6AuAdxidqSiCe7WL2aPylngQQ+wudJgoEXPgAnyZxXk/szXY7iwBNqHHRMGYNwCfDKmhr49stLDeGW64/qwodGpIvDX+nnhafhz43cLq2nZg9ZAxn1TUf8RkI9fvB2oyt/AwBC71Lx23AE/78u7v7h8PMXqBs8BHwFO+rl7px9Z6GNpudUnPmn+BqA1XzOjY/AJcqGn0ZM0JkajRwh0pVhpNNHqHptGf152NS9foTzWN1qw2mma03qqerxBqxaVr9GlNo8/VsnXi0jX6hKbRUpzXikvX6O80jf6s7mxcukbv1TRaXoVrxaVr9IOaRt9ZdzYuTaPPANdoGn1RhM3PcTR6t5rJXQlJY3ZtuPSMPg5cbdWeW1v14dIyWlYWJ9VNrqGpMWWjxeTNZiZ3JbZjERt93HQm99mcfXuRGX3Gt0Lo35MLtBvsbLDRbd8TslfqZNUSLsUvsboJaNAiWp9JSi1h/yOgQYvofSYpNqIT0EDsPpPoKG4IzHXtiF8CXAfc7SucczECGhaF0fPWly2d1/+BdatS/KCG2lF8U5wYQQMGV9UyacYBbgQe8P12tX7DcrhBRg9jv6575ZJ8jZovW+Ix8MswcxTXPuaq1rDE4y4bF4sleQXwp3JCJ/3BgA/Lg7CAhhj8UftRbsDzhgkeHvb6Sxy2xHN0cKLLjRsgD4VmNvbIR6vLXAr4PcWeNltlNgdiWyJtwOtcSvieZCsOBOJa8rhLEf8As5jZ7UBMq5n8kEsZ6RcGftTO3A2Op80PwO1uHPCfM8iu+U9KyZ8NxJLZp4Fo3SKLWm7c8Dsxk3ImEfDhCItQLYOjLOa9pm3+YR7nQ80YAHsqmrInMOYHFcd81zUVOsdpVmFjYMz7K46Z7rGYSreS6ZKGzABLAmMuqXCcxcHQmI2AzoeaRY81loNXVhYYc3WJQ1ok9iq3GKBjtszUEDNlDPFmD5vZ01XOAWnCbWQj8L7fqfnLz7b3/N9LX9r+NrLJj9nyYx7x/9/Q+NtFJpPJZDKZTCaTybgK/Au019QFmOUIHwAAAABJRU5ErkJggg==';

    // Exact icon geometry exported by the supplied Figma project.
    const ICONS = {
        mic: '<svg viewBox="0 0 14.0763 16" aria-hidden="true"><path d="M5.0188 4.87487C5.0188 4.37762 5.23152 3.90074 5.61017 3.54914C5.98882 3.19753 6.50238 3 7.03787 3C7.57337 3 8.08693 3.19753 8.46558 3.54914C8.84423 3.90074 9.05695 4.37762 9.05695 4.87487V7.37469C9.05695 7.87194 8.84423 8.34882 8.46558 8.70043C8.08693 9.05203 7.57337 9.24956 7.03787 9.24956C6.50238 9.24956 5.98882 9.05203 5.61017 8.70043C5.23152 8.34882 5.0188 7.87194 5.0188 7.37469V4.87487Z"/><path d="M7.03815 9.87522C6.32416 9.87522 5.63941 9.61185 5.13455 9.14304C4.62968 8.67423 4.34605 8.03839 4.34605 7.37539H3C2.99985 8.26163 3.33775 9.11928 3.95376 9.79619C4.56977 10.4731 5.42407 10.9256 6.36513 11.0733V11.7501H5.01908V13H9.05723V11.7501H7.71118V11.0733C8.65223 10.9256 9.50653 10.4731 10.1225 9.79619C10.7385 9.11928 11.0764 8.26163 11.0763 7.37539H9.73025C9.73025 8.03839 9.44662 8.67423 8.94175 9.14304C8.43689 9.61185 7.75214 9.87522 7.03815 9.87522Z"/></svg>',
        speaker: '<svg viewBox="0 0 6 10" aria-hidden="true"><path d="M5.58867 0.0543689C5.71046 0.108472 5.81454 0.200053 5.88776 0.317532C5.96097 0.43501 6.00003 0.573111 6 0.714373V9.28586C5.99997 9.42711 5.96086 9.56518 5.8876 9.68262C5.81435 9.80006 5.71024 9.89159 5.58844 9.94564C5.46664 9.99969 5.33261 10.0138 5.20331 9.98628C5.07401 9.95873 4.95523 9.89073 4.862 9.79086L2.39067 7.14299H0.666667C0.489856 7.14299 0.320286 7.06773 0.195262 6.93378C0.0702379 6.79982 0 6.61814 0 6.4287V3.57154C0 3.38209 0.0702379 3.20041 0.195262 3.06646C0.320286 2.9325 0.489856 2.85725 0.666667 2.85725H2.39067L4.862 0.20937C4.95523 0.109417 5.07403 0.0413389 5.20338 0.013748C5.33273-0.0138429 5.46682 0.000293622 5.58867 0.0543689Z"/></svg>',
        heart: '<svg viewBox="0 0 12 11" aria-hidden="true"><defs><linearGradient id="nxFigmaHeartFill" x1="6" x2="6" y1="0" y2="11" gradientUnits="userSpaceOnUse"><stop stop-color="#f0ca78"/><stop offset=".322115" stop-color="#fce7aa"/><stop offset=".644231" stop-color="#d7a757"/><stop offset="1" stop-color="#be893b"/></linearGradient><linearGradient id="nxFigmaHeartStroke" x1="6" x2="6" y1="0" y2="11" gradientUnits="userSpaceOnUse"><stop stop-color="#944f1b"/><stop offset="1" stop-color="#2e1908"/></linearGradient></defs><path d="M8.7002 0.5C10.2729 0.500101 11.4999 1.72185 11.5 3.29688C11.5 4.26232 11.0689 5.18086 10.207 6.23438C9.33967 7.29454 8.08892 8.42934 6.53418 9.83789L6.5332 9.83887L6 10.3232L5.4668 9.83887L5.46582 9.83789L4.35742 8.83008C3.3093 7.86689 2.44346 7.02946 1.79297 6.23438C0.931071 5.18086 0.5 4.26232 0.5 3.29688C0.500066 1.72185 1.72706 0.500101 3.2998 0.5C4.1928 0.5 5.05863 0.917548 5.62109 1.57227L6 2.01465L6.37891 1.57227C6.94137 0.917548 7.8072 0.5 8.7002 0.5Z" fill="url(#nxFigmaHeartFill)" stroke="url(#nxFigmaHeartStroke)"/></svg>',
        heartPulse: '<svg viewBox="0 0 9 9" aria-hidden="true"><path d="M6.35625 0C7.10625 0 7.73445 0.308333 8.24085 0.925C8.74725 1.54167 9.0003 2.275 9 3.125C9 3.275 8.9925 3.423 8.9775 3.569C8.9625 3.715 8.93625 3.85867 8.89875 4H6.08625L5.32125 2.725C5.28375 2.65833 5.23125 2.60417 5.16375 2.5625C5.09625 2.52083 5.025 2.5 4.95 2.5C4.8525 2.5 4.76445 2.53333 4.68585 2.6C4.60725 2.66667 4.5528 2.75 4.5225 2.85L3.915 4.875L3.52125 4.225C3.48375 4.15833 3.43125 4.10417 3.36375 4.0625C3.29625 4.02083 3.225 4 3.15 4H0.10125C0.06375 3.85833 0.0375 3.71467 0.0225 3.569C0.00749998 3.42333 0 3.2795 0 3.1375C0 2.27917 0.25125 1.54167 0.75375 0.925C1.25625 0.308333 1.8825 0 2.6325 0C2.9925 0 3.33195 0.0791666 3.65085 0.2375C3.96975 0.395833 4.2528 0.616667 4.5 0.9C4.74 0.616667 5.01945 0.395833 5.33835 0.2375C5.65725 0.0791666 5.99655 0 6.35625 0ZM4.5 9C4.365 9 4.2357 8.973 4.1121 8.919C3.9885 8.865 3.8778 8.78366 3.78 8.675L0.765 5.3125C0.72 5.2625 0.67875 5.2125 0.64125 5.1625C0.60375 5.1125 0.56625 5.05833 0.52875 5H2.9025L3.6675 6.275C3.705 6.34166 3.7575 6.39583 3.825 6.4375C3.8925 6.47916 3.96375 6.5 4.03875 6.5C4.13625 6.5 4.22625 6.46666 4.30875 6.4C4.39125 6.33333 4.4475 6.25 4.4775 6.15L5.085 4.125L5.4675 4.775C5.5125 4.84167 5.56875 4.89583 5.63625 4.9375C5.70375 4.97917 5.775 5 5.85 5H8.46L8.3475 5.15L8.235 5.3L5.20875 8.675C5.11125 8.78333 5.0025 8.86466 4.8825 8.919C4.7625 8.97333 4.635 9.00033 4.5 9Z"/></svg>',
        food: '<svg viewBox="0 0 11 11" aria-hidden="true"><path d="M9.98847 5.90151C10.3542 5.53642 10.6331 5.09381 10.8046 4.60641C10.9761 4.11902 11.0358 3.59932 10.9793 3.08574C10.9228 2.57216 10.7516 2.07785 10.4782 1.63936C10.2049 1.20088 9.8364 0.829441 9.40008 0.552522C8.29479-0.178635 6.81558-0.184132 5.69929 0.53603C4.73148 1.15724 4.19808 2.12478 4.1046 3.12531C4.03311 3.85097 3.75816 4.52716 3.25226 5.03292L3.23576 5.04941C2.59788 5.68711 2.59788 6.66015 3.19727 7.25388L3.74167 7.79812C4.02977 8.08595 4.4204 8.24764 4.82771 8.24764C5.23501 8.24764 5.62565 8.08595 5.91375 7.79812C6.44715 7.26487 7.15101 6.97351 7.91537 6.89105C8.66872 6.80859 9.40558 6.47874 9.98847 5.90151ZM2.34493 9.82117C2.4934 10.129 2.44391 10.5029 2.18546 10.7557C2.07353 10.8693 1.93086 10.9478 1.77497 10.9815C1.61908 11.0152 1.45673 11.0027 1.30785 10.9455C1.15897 10.8883 1.03003 10.7889 0.936836 10.6595C0.843645 10.5301 0.790261 10.3763 0.783231 10.217C0.623889 10.21 0.470062 10.1566 0.340621 10.0634C0.21118 9.97026 0.111753 9.84135 0.0545358 9.69251C-0.00268138 9.54367-0.0152004 9.38137 0.0185142 9.22552C0.0522289 9.06967 0.130711 8.92705 0.244334 8.81514C0.497286 8.56226 0.876713 8.50729 1.17916 8.65572L2.54289 7.31985C2.61988 7.4243 2.70786 7.54524 2.80684 7.64419L3.35124 8.18844C3.46672 8.29839 3.5767 8.39184 3.71967 8.4743L2.34493 9.82117Z"/></svg>',
        water: '<svg viewBox="0 0 6 10" aria-hidden="true"><path d="M3 10C2.20435 10 1.44129 9.6226 0.87868 8.95083C0.316071 8.27906 0 7.36794 0 6.41791C0 4.02985 3 0 3 0C3 0 6 4.02985 6 6.41791C6 7.36794 5.68393 8.27906 5.12132 8.95083C4.55871 9.6226 3.79565 10 3 10Z"/></svg>',
        brain: `<img src="${FIGMA_BRAIN}" alt="" aria-hidden="true">`,
        core: `<img src="${FIGMA_BRAIN}" alt="" aria-hidden="true">`,
        bolt: '<svg viewBox="0 0 6 11" aria-hidden="true"><path d="M2.5 7H0L3.5 0V4H6L2.5 11V7Z"/></svg>',
        saddle: '<svg viewBox="0 0 10 9.00014" aria-hidden="true"><path d="M8.5 4.99978V5.49978C8.5 5.97236 8.25612 6.72766 7.49805 6.93728C7.33721 6.9802 7.17134 7.00124 7.00488 6.99978H3C2.80697 6.99978 2.64366 6.9762 2.50586 6.93826H2.50488C1.7446 6.72973 1.5 5.97295 1.5 5.49978V4.99978H8.5Z" fill="currentColor" stroke="currentColor"/><path d="M9 5.5V4.5H1V5.5C1 6.069 1.2915 7.124 2.3725 7.4205C2.5575 7.4715 2.766 7.5 3 7.5H7C7.21179 7.5019 7.42287 7.47516 7.6275 7.4205C8.7085 7.124 9 6.069 9 5.5Z"/><path d="M0.5 4.5H9M7.6275 7.4205C7.42287 7.47516 7.21179 7.5019 7 7.5H3C2.766 7.5 2.5575 7.4715 2.3725 7.4205C1.2915 7.124 1 6.069 1 5.5V4.5M9 4.5C9.13261 4.5 9.25979 4.44732 9.35355 4.35355C9.44732 4.25979 9.5 4.13261 9.5 4V2C9.5 1.5 9.2 0.5 8 0.5C6.8 0.5 6.5 1.5 6.5 2M6.5 2H5.5M6.5 2H7.5M7.6275 7.4205L8 8.5M2.3725 7.4205L2 8.5" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/></svg>'
    };

    const DEFAULT_STATUS_ICONS = [
        { key: 'food', icon: 'food' },
        { key: 'water', icon: 'water' },
        { key: 'core', icon: 'brain' }
    ];

    // วงกลมที่ "ไม่ได้" มาจาก Config.StatusIcons ฝั่ง client — client ส่งค่าพวกนี้มาคนละ payload
    // (mic มากับ hud:update.voice.talking, horse* มากับ horse:update) ถ้าเอาไปใส่ Config.StatusIcons
    // ค่าจะโดน item.default ทับ เลยต้อง append เองที่นี่ และการ append ท้ายเสมอคือสิ่งที่การันตี
    // ลำดับซ้าย→ขวา: food, water, core, mic, แล้วค่อย 3 วงม้า
    const EXTRA_STATUS_ICONS = [
        { key: 'mic', icon: 'mic' },
        { key: 'horseHealth', icon: 'heartPulse' },
        { key: 'horseStamina', icon: 'bolt' },
        { key: 'horseCondition', icon: 'saddle' }
    ];

    // เดิม hard-code เลข 3 กระจายอยู่หลายที่ (normalizeStatusMeta / ensureStatusNode /
    // updateStatusIcons) ทำให้วงที่ 4 ขึ้นไปถูกตัดทิ้งเงียบ ๆ รวบมาเป็นค่าเดียวเผื่อขยายอีก
    const MAX_STATUS_ICONS = 12;

    // map ชื่อ field ใน payload horse:update -> key ของวงกลม
    const HORSE_STATUS_KEYS = {
        health: 'horseHealth',
        stamina: 'horseStamina',
        condition: 'horseCondition'
    };

    const state = {
        visible: true,
        secondaryEnabled: true,
        statusIcons: DEFAULT_STATUS_ICONS,
        layoutScale: 1,
        layoutMain: {
            left: 18,
            top: 24,
            bottom: 28
        },
        horseVisible: false,
        horseHasCondition: true,
        micActive: false,
        radarVisible: false,
        radarDebug: false,
        radarMode: 'horse',
        radarTheme: 'detailed',
        radarZoom: 6,
        radarTileSize: 256,
        coordinateScale: 0.01552,
        longitudeOffset: 111.29,
        latitudeOffset: -63.6,
        tileUrls: {},
        fallbackTileUrl: '',
        radarTiles: new Map(),
        radarX: 0,
        radarY: 0,
        radarHeading: 0,
        radarHasPosition: false
    };

    const els = {
        root: document.getElementById('nxHudRoot'),
        radar: document.getElementById('nxRadarMap'),
        radarViewport: document.getElementById('nxMapViewport'),
        radarTiles: document.getElementById('nxMapTiles'),
        radarPlayer: document.getElementById('nxMapPlayer'),
        radarDebug: document.getElementById('nxRadarDebug'),
        playerId: document.getElementById('nxPlayerId'),
        micBox: document.getElementById('nxMicBox'),
        voiceMode: document.getElementById('nxVoiceMode'),
        healthRow: document.querySelector('.nx-health-row'),
        healthFill: document.getElementById('nxHealthFill'),
        secondaryBar: document.getElementById('nxSecondaryBar'),
        secondaryFill: document.getElementById('nxSecondaryFill'),
        statusIcons: document.getElementById('nxStatusIcons')
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

    function scaledScreenLength(value, fallback, scale) {
        if (typeof value === 'number' && Number.isFinite(value)) {
            return `${value * scale}px`;
        }

        if (typeof value === 'string') {
            const trimmed = value.trim();
            const pixelMatch = trimmed.match(/^(-?\d+(?:\.\d+)?)(?:px)?$/);

            if (pixelMatch) {
                return `${Number(pixelMatch[1]) * scale}px`;
            }

            return cssLength(trimmed, fallback);
        }

        return `${fallback * scale}px`;
    }

    function applyResponsiveLayout() {
        const docStyle = document.documentElement.style;
        const viewportScale = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
        const safeViewportScale = Number.isFinite(viewportScale) && viewportScale > 0 ? viewportScale : 1;

        docStyle.setProperty('--hud-scale', String(state.layoutScale * safeViewportScale));
        docStyle.setProperty('--hud-left', scaledScreenLength(state.layoutMain.left, 18, safeViewportScale));
        docStyle.setProperty('--hud-top', scaledScreenLength(state.layoutMain.top, 24, safeViewportScale));
        docStyle.setProperty('--hud-bottom', scaledScreenLength(state.layoutMain.bottom, 28, safeViewportScale));
    }

    function applyLayout(layout) {
        if (!isObject(layout)) {
            return;
        }

        const docStyle = document.documentElement.style;
        const scale = Number(layout.Scale);

        if (Number.isFinite(scale) && scale > 0) {
            state.layoutScale = Math.max(0.6, Math.min(1.4, scale));
        }

        if (isObject(layout.Main)) {
            const main = layout.Main;
            const anchor = cleanText(main.Anchor, 'bottom-left');

            if (els.root) {
                els.root.dataset.anchor = anchor === 'top-left' ? 'top-left' : 'bottom-left';
            }

            state.layoutMain.left = main.Left !== undefined ? main.Left : 18;
            state.layoutMain.top = main.Top !== undefined ? main.Top : 24;
            state.layoutMain.bottom = main.Bottom !== undefined ? main.Bottom : 28;
        }

        if (isObject(layout.Horse)) {
            docStyle.setProperty('--horse-left', cssLength(layout.Horse.Left, '642px'));
            docStyle.setProperty('--horse-bottom', cssLength(layout.Horse.Bottom, '4px'));
        }

        if (isObject(layout.Main)) {
            docStyle.setProperty('--hud-width', cssLength(layout.Main.Width, '410px'));
            docStyle.setProperty('--hud-height', cssLength(layout.Main.Height, '300px'));
        }

        applyResponsiveLayout();
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
            .slice(0, MAX_STATUS_ICONS)
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

        // ต่อท้ายด้วย EXTRA_STATUS_ICONS เสมอ และ dedupe เผื่อ config ฝั่ง server
        // ส่ง key ซ้ำมา (จะได้ไม่เกิดวงซ้อนกันสองวง)
        const configured = normalizeStatusMeta(items);
        const seen = new Set(configured.map((item) => item.key));
        state.statusIcons = configured.concat(EXTRA_STATUS_ICONS.filter((item) => !seen.has(item.key)));

        state.statusIcons.forEach((item) => {
            const node = createStatusNode(item);
            statusNodes.set(item.key, node);
            els.statusIcons.appendChild(node);
        });

        // config อาจถูกส่งมาใหม่ระหว่างเกม (เช่น restart NUI) — ต้อง reapply สถานะปัจจุบัน
        // ไม่งั้นวงม้าจะโผล่ทั้งที่ลงจากม้าแล้ว
        applyHorseVisibility();
        applyMicActive(state.micActive);
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

        if (els.statusIcons && statusNodes.size <= MAX_STATUS_ICONS) {
            els.statusIcons.appendChild(node);
        }

        return node;
    }

    function applyStatusValue(node, value) {
        if (!node) {
            return;
        }

        const missing = value === null || value === undefined;
        const percent = clampPercent(value, 0);

        node.style.setProperty('--value', `${percent}%`);
        node.classList.toggle('is-muted', missing);
        node.classList.toggle('is-warning', !missing && percent <= 35 && percent > 15);
        node.classList.toggle('is-critical', !missing && percent <= 15);
    }

    function updateStatusIcons(icons) {
        statusListFromPayload(icons).slice(0, MAX_STATUS_ICONS).forEach((item) => {
            const node = ensureStatusNode(item);

            if (!node) {
                return;
            }

            if (item.icon) {
                setIcon(node.querySelector('.nx-svg-icon'), item.icon);
            }

            applyStatusValue(node, item.value);
        });
    }

    // mic ไม่มีค่าเปอร์เซ็นต์ ริงเต็มวงตลอด ใช้แค่คลาส is-talking สลับสว่าง/หรี่
    function applyMicActive(active) {
        state.micActive = active === true;

        const node = statusNodes.get('mic');

        if (node) {
            node.style.setProperty('--value', '100%');
            node.classList.toggle('is-talking', state.micActive);
        }
    }

    function applyHorseVisibility() {
        // ซ่อนวงม้าทั้งสามเมื่อไม่ได้ขี่ม้า และซ่อน condition แยกอีกชั้นถ้า client ไม่ส่งค่ามา
        // (Config.Horse.ThirdStatEnabled = false) ใช้ is-hidden = display:none วงข้างหน้าจึงไม่ขยับ
        Object.keys(HORSE_STATUS_KEYS).forEach((field) => {
            const node = statusNodes.get(HORSE_STATUS_KEYS[field]);

            if (!node) {
                return;
            }

            const hidden = !state.horseVisible || (field === 'condition' && !state.horseHasCondition);
            node.classList.toggle('is-hidden', hidden);
        });
    }

    function setHudVisible(visible) {
        state.visible = visible;

        if (els.root) {
            els.root.classList.toggle('is-visible', visible);
        }
    }

    // ขับด้วยสัญญาณเดิมทุกอย่าง: horse:setVisible (client sendHorseVisibility)
    // และ horse:update.horse.mounted — ไม่ได้เพิ่ม signal ใหม่
    function setHorseVisible(visible) {
        state.horseVisible = visible === true;
        applyHorseVisibility();
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

        if (voice.talking !== undefined) {
            const talking = boolFromPayload(voice.talking);

            if (els.micBox) {
                els.micBox.classList.toggle('is-talking', talking);
            }

            applyMicActive(talking);
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

        if (horse.health !== undefined) {
            applyStatusValue(statusNodes.get(HORSE_STATUS_KEYS.health), horse.health);
        }

        if (horse.stamina !== undefined) {
            applyStatusValue(statusNodes.get(HORSE_STATUS_KEYS.stamina), horse.stamina);
        }

        state.horseHasCondition = horse.condition !== null && horse.condition !== undefined;

        if (state.horseHasCondition) {
            applyStatusValue(statusNodes.get(HORSE_STATUS_KEYS.condition), horse.condition);
        }

        // ตั้งค่าตัวเลขให้เสร็จก่อนค่อยสั่งโชว์ ไม่งั้นวงจะแวบขึ้นมาพร้อมค่าเก่าของม้าตัวก่อน
        if (horse.mounted !== undefined) {
            setHorseVisible(boolFromPayload(horse.mounted));
        } else {
            applyHorseVisibility();
        }
    }

    function replaceTileTokens(template, z, x, y) {
        return String(template || '')
            .replaceAll('{z}', String(z))
            .replaceAll('{x}', String(x))
            .replaceAll('{y}', String(y));
    }

    function clearRadarTiles() {
        state.radarTiles.forEach((tile) => tile.remove());
        state.radarTiles.clear();
    }

    function setRadarVisible(visible) {
        state.radarVisible = boolFromPayload(visible);

        if (els.radar) {
            els.radar.classList.toggle('is-hidden', !state.radarVisible);
            els.radar.setAttribute('aria-hidden', state.radarVisible ? 'false' : 'true');
        }
    }

    function currentTileTemplate() {
        return state.tileUrls[state.radarTheme] || state.tileUrls.original || '';
    }

    function createRadarTile(tileX, tileY) {
        const key = `${state.radarZoom}:${state.radarTheme}:${tileX}:${tileY}`;
        let tile = state.radarTiles.get(key);

        if (tile) {
            return tile;
        }

        tile = document.createElement('img');
        tile.alt = '';
        tile.draggable = false;
        tile.dataset.fallbackUsed = 'false';
        tile.style.width = `${state.radarTileSize}px`;
        tile.style.height = `${state.radarTileSize}px`;
        tile.src = replaceTileTokens(currentTileTemplate(), state.radarZoom, tileX, tileY);
        tile.onerror = () => {
            if (tile.dataset.fallbackUsed === 'true' || !state.fallbackTileUrl || state.radarZoom > 6) {
                tile.style.visibility = 'hidden';
                return;
            }

            tile.dataset.fallbackUsed = 'true';
            tile.src = replaceTileTokens(state.fallbackTileUrl, state.radarZoom, tileX, tileY);
        };

        els.radarTiles.appendChild(tile);
        state.radarTiles.set(key, tile);
        return tile;
    }

    function renderRadarMap() {
        if (!state.radarHasPosition || !els.radarViewport || !els.radarTiles) {
            return;
        }

        const tileSize = state.radarTileSize;
        const scale = 2 ** state.radarZoom;
        const longitude = (state.coordinateScale * state.radarX) + state.longitudeOffset;
        const latitude = (state.coordinateScale * state.radarY) + state.latitudeOffset;
        const centerX = longitude * scale;
        const centerY = -latitude * scale;
        const centerTileX = Math.floor(centerX / tileSize);
        const centerTileY = Math.floor(centerY / tileSize);
        const halfWidth = els.radarViewport.clientWidth / 2;
        const halfHeight = els.radarViewport.clientHeight / 2;
        const radiusX = Math.ceil(halfWidth / tileSize) + 1;
        const radiusY = Math.ceil(halfHeight / tileSize) + 1;
        const maxTile = (2 ** state.radarZoom) - 1;
        const wanted = new Set();

        for (let tileY = centerTileY - radiusY; tileY <= centerTileY + radiusY; tileY += 1) {
            for (let tileX = centerTileX - radiusX; tileX <= centerTileX + radiusX; tileX += 1) {
                if (tileX < 0 || tileY < 0 || tileX > maxTile || tileY > maxTile) {
                    continue;
                }

                const key = `${state.radarZoom}:${state.radarTheme}:${tileX}:${tileY}`;
                const tile = createRadarTile(tileX, tileY);
                wanted.add(key);
                tile.style.left = `${Math.round((tileX * tileSize) - centerX + halfWidth)}px`;
                tile.style.top = `${Math.round((tileY * tileSize) - centerY + halfHeight)}px`;
            }
        }

        state.radarTiles.forEach((tile, key) => {
            if (!wanted.has(key)) {
                tile.remove();
                state.radarTiles.delete(key);
            }
        });

        if (els.radarPlayer) {
            els.radarPlayer.style.transform = `rotate(${state.radarHeading}deg)`;
        }

        if (els.radarDebug) {
            els.radarDebug.textContent = `x ${state.radarX.toFixed(1)} y ${state.radarY.toFixed(1)} h ${state.radarHeading.toFixed(0)}° z${state.radarZoom} ${state.radarTheme}`;
        }
    }

    function updateRadarMap(data) {
        state.radarX = Number.isFinite(Number(data.x)) ? Number(data.x) : state.radarX;
        state.radarY = Number.isFinite(Number(data.y)) ? Number(data.y) : state.radarY;
        state.radarHeading = Number.isFinite(Number(data.heading)) ? Number(data.heading) : state.radarHeading;
        state.radarHasPosition = true;
        renderRadarMap();
    }

    function applyRadarConfig(radarConfig) {
        if (!isObject(radarConfig)) {
            return;
        }

        const layout = isObject(radarConfig.layout) ? radarConfig.layout : {};
        const map = isObject(radarConfig.map) ? radarConfig.map : {};
        const style = isObject(radarConfig.style) ? radarConfig.style : {};
        const docStyle = document.documentElement.style;
        const nextTheme = cleanText(radarConfig.theme || map.Theme, 'detailed').toLowerCase();
        let nextZoom = Math.floor(Number(radarConfig.zoom || map.Zoom || 6));

        if (nextTheme === 'original' && nextZoom > 6) {
            nextZoom = 6;
        }

        const sourceChanged = nextTheme !== state.radarTheme || nextZoom !== state.radarZoom;
        state.radarMode = cleanText(radarConfig.mode, state.radarMode).toLowerCase();
        state.radarTheme = nextTheme;
        state.radarZoom = Number.isFinite(nextZoom) ? nextZoom : 6;
        state.radarTileSize = Number(map.TileSize) || 256;
        state.coordinateScale = Number(map.CoordinateScale) || 0.01552;
        state.longitudeOffset = Number(map.LongitudeOffset) || 111.29;
        state.latitudeOffset = Number(map.LatitudeOffset) || -63.6;
        state.tileUrls = isObject(map.TileUrls) ? map.TileUrls : state.tileUrls;
        state.fallbackTileUrl = state.tileUrls.original || '';
        state.radarDebug = boolFromPayload(radarConfig.debug);

        docStyle.setProperty('--radar-left', cssLength(layout.Left, '0px'));
        docStyle.setProperty('--radar-bottom', cssLength(layout.Bottom, '67px'));
        docStyle.setProperty('--radar-size', cssLength(layout.Size, '210px'));
        docStyle.setProperty('--radar-opacity', String(clampPercent((Number(layout.Opacity) || 0.98) * 100) / 100));

        if (style.Frame) docStyle.setProperty('--radar-frame', style.Frame);
        if (style.FrameAccent) docStyle.setProperty('--radar-accent', style.FrameAccent);
        if (style.Player) docStyle.setProperty('--radar-player', style.Player);
        if (style.PlayerOutline) docStyle.setProperty('--radar-player-outline', style.PlayerOutline);
        if (style.Tint) docStyle.setProperty('--radar-tint', style.Tint);
        docStyle.setProperty('--radar-tint-opacity', String(Number(style.TintOpacity) || 0));

        if (els.radar) {
            els.radar.classList.toggle('is-debug', state.radarDebug);
            els.radar.dataset.mode = state.radarMode;
            els.radar.dataset.theme = state.radarTheme;
        }

        if (sourceChanged) {
            clearRadarTiles();
        }

        renderRadarMap();
    }

    function applyConfig(data) {
        applyLayout(data.layout);

        if (data.radarMap !== undefined) {
            applyRadarConfig(data.radarMap);
        }

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
            case 'radar:setVisible':
                setRadarVisible(data.visible !== undefined ? data.visible : data.show);
                break;
            case 'radar:setMode':
                state.radarMode = cleanText(data.mode, state.radarMode).toLowerCase();
                if (els.radar) els.radar.dataset.mode = state.radarMode;
                break;
            case 'radar:update':
                updateRadarMap(data);
                break;
            default:
                break;
        }
    });

    let readyAttempts = 0;
    async function notifyReady() {
        if (typeof window.GetParentResourceName !== 'function') {
            return;
        }

        readyAttempts += 1;

        try {
            const response = await fetch(`https://${window.GetParentResourceName()}/ready`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: '{}'
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
        } catch (error) {
            if (readyAttempts < 20) {
                window.setTimeout(notifyReady, 500);
            } else {
                console.error('[nx_hud] NUI ready callback failed', error);
            }
        }
    }

    hydrateStaticIcons();
    renderStatusIcons(DEFAULT_STATUS_ICONS);
    setHudVisible(false);
    setHorseVisible(false);
    setRadarVisible(false);
    notifyReady();
    window.addEventListener('resize', () => {
        applyResponsiveLayout();
        renderRadarMap();
    });

    if (window.location.protocol === 'file:' && window.location.search.includes('preview')) {
        applyConfig({
            layout: {
                Scale: 1,
                Main: { Left: 18, Bottom: 28, Width: 410, Height: 300 },
                Horse: { Left: 345, Bottom: 4 }
            },
            radarMap: {
                mode: 'horse',
                theme: 'detailed',
                zoom: 6,
                layout: { Left: 0, Bottom: 67, Size: 210, Opacity: 0.98 },
                map: {
                    TileSize: 256,
                    CoordinateScale: 0.01552,
                    LongitudeOffset: 111.29,
                    LatitudeOffset: -63.6,
                    TileUrls: {
                        original: 'https://s.rsg.sc/sc/images/games/RDR2/map/game/{z}/{x}/{y}.jpg',
                        detailed: 'https://map-tiles.b-cdn.net/assets/rdr3/webp/detailed/{z}/{x}_{y}.webp'
                    }
                },
                style: {}
            },
            secondaryBar: { enabled: true },
            statusIcons: DEFAULT_STATUS_ICONS
        });
        setHudVisible(true);
        setHorseVisible(true);
        setRadarVisible(true);
        updateHud({
            player: { id: 9999 },
            voice: { mode: 'NORMAL', talking: true },
            status: {
                health: 87,
                secondary: 64,
                icons: [
                    { key: 'food', icon: 'food', value: 92 },
                    { key: 'water', icon: 'water', value: 71 },
                    { key: 'core', icon: 'core', value: 48 }
                ]
            }
        });
        updateHorse({ horse: { mounted: true, health: 82, stamina: 58, condition: 76 } });
        updateRadarMap({ x: -282.5, y: 806.5, heading: 72 });
    }
})();
