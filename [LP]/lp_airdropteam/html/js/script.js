var I_PPL = '<svg viewBox="0 0 16 16" fill="currentColor"><circle cx="8" cy="5" r="3"/><path d="M2 15a6 6 0 0112 0z"/></svg>';

function escapeHtml(s) {
    return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

window.addEventListener('message', function(event) {
    switch(event.data.action) {
        case 'SyncAirdropTime':
            const item = event.data.Airdrop;
            createAirdrop(item.id, item.Label, event.data.Time);
            break;

        case 'UpdateAirdropPlayers':
            updateAirdropPlayers(event.data.id, event.data.players, event.data.maxPlayers);
            break;

        case 'RemoveAirdrop':
            removeAirdrop(event.data.id);
            break;
    }
});

// cache player counts if UI card not created yet
const __playersCache = {}; // { [id]: {players,maxPlayers} }

function removeAirdrop(id) {
    const el = document.getElementById(`airdrop-${id}`);
    if (el) el.remove();
}

function formatTime(seconds) {
    seconds = Math.max(0, seconds | 0);
    const m = Math.floor(seconds / 60), s = seconds % 60;
    return `${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`;
}

// นับถอยหลังตัวเดียวต่อ timer (เก็บ interval ไว้บน element เพื่อล้างก่อนเริ่มใหม่ = กัน interval ซ้อน)
function startCountdown(timer, countdown) {
    if (timer._iv) clearInterval(timer._iv);
    function paint() {
        if (countdown > 0) {
            timer.textContent = formatTime(countdown);
            timer.classList.toggle('warn', countdown <= 60);
            timer.classList.remove('ready');
        } else {
            timer.textContent = 'Ready';
            timer.classList.remove('warn');
            timer.classList.add('ready');
        }
    }
    paint();
    timer._iv = setInterval(function () {
        if (countdown > 0) { countdown--; paint(); }
        else { clearInterval(timer._iv); timer._iv = null; }
    }, 1000);
}

function createAirdrop(id, name, countdown) {
    const container = document.querySelector('.airdrop-container');
    let item = document.getElementById(`airdrop-${id}`);

    if (item) {
        // การ์ดมีอยู่แล้ว → รีสตาร์ทเฉพาะ countdown
        startCountdown(item.querySelector('.p-timer'), countdown);
        return;
    }

    item = document.createElement('div');
    item.className = 'airdrop-item';
    item.id = `airdrop-${id}`;
    item.innerHTML =
        '<div class="ev-title">Airdrop</div>' +
        '<div class="plate"><div class="inner">' +
            '<span class="title">' + escapeHtml(name) + '</span>' +
            '<div class="inrow">' +
                '<span class="p-ppl">' + I_PPL + '<span id="airdropPlayers-' + id + '">-</span></span>' +
                '<span class="divider"></span>' +
                '<span class="p-timer timer">' + formatTime(countdown) + '</span>' +
            '</div>' +
        '</div></div>';
    container.appendChild(item);

    if (__playersCache[id]) updateAirdropPlayers(id, __playersCache[id].players, __playersCache[id].maxPlayers);
    startCountdown(item.querySelector('.p-timer'), countdown);
}

function updateAirdropPlayers(id, players, maxPlayers) {
    if (id === undefined || id === null) return;
    const el = document.getElementById(`airdropPlayers-${id}`);
    const p = Number(players) || 0;
    const m = Number(maxPlayers) || 0;

    if (!el) { __playersCache[id] = { players: p, maxPlayers: m }; return; }
    el.textContent = m > 0 ? `${p}/${m}` : `${p}`;
}
