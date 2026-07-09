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
        
        // other cases
    }
});

// cache player counts if UI card not created yet
const __playersCache = {}; // { [id]: {players,maxPlayers} }

// Function to remove an airdrop from the UI by its ID
function removeAirdrop(id) {
    const airdropItem = document.getElementById(`airdrop-${id}`);
    if (airdropItem) {
        airdropItem.remove();
    }
}

// Function to format time as MM:SS
function formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes < 10 ? '0' : ''}${minutes}:${remainingSeconds < 10 ? '0' : ''}${remainingSeconds}`;
}

function createAirdrop(id, name, countdown) {
    const container = document.querySelector('.airdrop-container');

    // Check if an airdrop with this ID already exists
    let airdropItem = document.getElementById(`airdrop-${id}`);
    if (airdropItem) {
        // If it exists, just update the countdown
        const timer = airdropItem.querySelector('.timer');
        const blinkingDot = airdropItem.querySelector('.blinking-dot');
        timer.textContent = formatTime(countdown);

        // Update the countdown and its styles
        const countdownInterval = setInterval(() => {
            if (countdown > 0) {
                countdown--;
                timer.textContent = formatTime(countdown);
                if (countdown < 10) {
                    timer.classList.add('low-time');
                    blinkingDot.classList.add('blinking-red');
                } else {
                    timer.classList.remove('low-time');
                    blinkingDot.classList.remove('blinking-red');
                }
            } else {
                clearInterval(countdownInterval);
                timer.textContent = "Ready";
                timer.classList.add('blinking-text'); // Add blinking-text class to the timer
                timer.classList.remove('low-time');
                blinkingDot.classList.remove('blinking-red');
                blinkingDot.classList.add('blinking-dot', 'ready'); // Add blinking-dot class to the dot
                const image = airdropItem.querySelector('.airdrop-image');
                image.style.filter = 'grayscale(100%)'; // Make the image grayscale
            }
        }, 1000);
    } else {
        // If it does not exist, create a new airdrop item
        airdropItem = document.createElement('div');
        airdropItem.className = 'airdrop-item';
        airdropItem.id = `airdrop-${id}`;

        const blinkingDot = document.createElement('div');
        blinkingDot.className = 'blinking-dot';

        const image = document.createElement('img');
        image.src = '/html/img/airdrop.png';
        image.className = 'airdrop-image';
        image.alt = 'Airdrop';

        const status = document.createElement('div');
        status.className = 'airdrop-status';

        const title = document.createElement('div');
        title.className = 'airdrop-title';
        title.textContent = name;

        const timer = document.createElement('span');
        timer.className = 'timer';
        timer.textContent = formatTime(countdown);

        status.appendChild(title);
        status.appendChild(timer);

        const playersLine = document.createElement('div');
        playersLine.className = 'airdrop-players';
        playersLine.id = `airdropPlayers-${id}`;
        playersLine.textContent = '';
        status.appendChild(playersLine);

        airdropItem.appendChild(blinkingDot);
        airdropItem.appendChild(image);
        airdropItem.appendChild(status);
        container.appendChild(airdropItem);

        // Apply cached players if available
        if (__playersCache[id]) {
            updateAirdropPlayers(id, __playersCache[id].players, __playersCache[id].maxPlayers);
        }

        // Start countdown
        const countdownInterval = setInterval(() => {
            if (countdown > 0) {
                countdown--;
                timer.textContent = formatTime(countdown);
                if (countdown < 10) {
                    timer.classList.add('low-time');
                    blinkingDot.classList.add('blinking-red');
                } else {
                    timer.classList.remove('low-time');
                    blinkingDot.classList.remove('blinking-red');
                }
            } else {
                clearInterval(countdownInterval);
                timer.textContent = "Ready";
                timer.classList.add('blinking-text'); // Add blinking-text class to the timer
                timer.classList.remove('low-time');
                blinkingDot.classList.remove('blinking-red');
                blinkingDot.classList.add('blinking-dot', 'ready'); // Add blinking-dot class to the dot
                image.style.filter = 'grayscale(100%)'; // Make the image grayscale
            }
        }, 1000);
    }
}

function updateAirdropPlayers(id, players, maxPlayers) {
    if (id === undefined || id === null) return;
    const el = document.getElementById(`airdropPlayers-${id}`);
    const p = Number(players) || 0;
    const m = Number(maxPlayers) || 0;

    if (!el) {
        __playersCache[id] = { players: p, maxPlayers: m };
        return;
    }

    if (m > 0) el.textContent = `ผู้เล่น: ${p}/${m}`;
    else el.textContent = `ผู้เล่น: ${p}`;
}



