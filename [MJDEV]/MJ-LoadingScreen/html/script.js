// © 2026 MJDev | All rights reserved
document.addEventListener("DOMContentLoaded", () => {
    document.getElementById('server-title').innerText = LSConfig.ServerTitle;
    document.getElementById('server-subtitle').innerText = LSConfig.ServerSubtitle;
    document.getElementById('discord-text').innerText = LSConfig.DiscordLink;
    document.getElementById('website-text').innerText = LSConfig.WebsiteLink;

    const rulesList = document.getElementById('rules-list');
    LSConfig.Rules.forEach((rule, index) => {
        let li = document.createElement('li');
        li.innerHTML = `<span class="rule-num">${index + 1}</span> <span>${rule}</span>`;
        rulesList.appendChild(li);
    });

    const bgContainer = document.getElementById('bg-container');
    LSConfig.Backgrounds.forEach((bg, index) => {
        let div = document.createElement('div');
        div.className = index === 0 ? 'bg-slide active' : 'bg-slide';
        div.style.backgroundImage = `url('${bg}')`;
        bgContainer.appendChild(div);
    });

    let currentBg = 0;
    const slides = document.querySelectorAll('.bg-slide');
    if(slides.length > 1) {
        setInterval(() => {
            slides[currentBg].classList.remove('active');
            currentBg = (currentBg + 1) % slides.length;
            slides[currentBg].classList.add('active');
        }, LSConfig.BackgroundSpeed);
    }

    let currentTip = 0;
    const tipElement = document.getElementById('tip-text');
    tipElement.innerText = LSConfig.Tips[0];
    setInterval(() => {
        currentTip = (currentTip + 1) % LSConfig.Tips.length;
        tipElement.style.opacity = 0;
        setTimeout(() => {
            tipElement.innerText = LSConfig.Tips[currentTip];
            tipElement.style.opacity = 1;
        }, 500); 
    }, LSConfig.TipSpeed);

    const audio = document.getElementById('bgm');
    const playBtn = document.getElementById('play-pause-btn');
    const volSlider = document.getElementById('volume-slider');
    
    document.getElementById('music-title').innerText = LSConfig.MusicTitle;
    document.getElementById('music-author').innerText = LSConfig.MusicAuthor;
    
    audio.src = LSConfig.Music;
    audio.volume = LSConfig.DefaultVolume;
    volSlider.value = LSConfig.DefaultVolume;

    audio.play().catch(e => console.log("Auto-play prevented. User interaction required."));

    playBtn.addEventListener('click', () => {
        if (audio.paused) {
            audio.play();
            playBtn.innerHTML = '<i class="fas fa-pause"></i>';
        } else {
            audio.pause();
            playBtn.innerHTML = '<i class="fas fa-play"></i>';
        }
    });

    volSlider.addEventListener('input', (e) => { audio.volume = e.target.value; });

    window.addEventListener('message', function(e) {
        if (e.data.eventName === 'loadProgress') {
            const progress = Math.round(e.data.loadFraction * 100);
            document.getElementById('progress-bar').style.width = progress + '%';
            document.getElementById('progress-text').innerText = progress + '%';
        }
    });

    document.getElementById('discord-btn').addEventListener('click', () => window.invokeNative ? window.invokeNative("openUrl", "https://" + LSConfig.DiscordLink) : window.open("https://" + LSConfig.DiscordLink));
    document.getElementById('website-btn').addEventListener('click', () => window.invokeNative ? window.invokeNative("openUrl", "https://" + LSConfig.WebsiteLink) : window.open("https://" + LSConfig.WebsiteLink));
});