var root = document.getElementById('root');
var badges = {
  delcar: document.getElementById('badge-delcar'),
  restart: document.getElementById('badge-restart'),
};
var audioPlayer = document.getElementById('audio-player');
var activeMode = null;

function hide() {
  root.classList.add('hidden');
  if (activeMode) {
    badges[activeMode].classList.add('hidden');
    activeMode = null;
  }
}

function show(mode, txtMin, txtSec) {
  if (!badges[mode]) return;

  if (activeMode && activeMode !== mode) {
    badges[activeMode].classList.add('hidden');
  }

  activeMode = mode;
  var badge = badges[mode];
  badge.querySelector('.txtMin').textContent = txtMin;
  badge.querySelector('.txtSec').textContent = txtSec;
  badge.classList.remove('hidden');
  root.classList.remove('hidden');
}

window.addEventListener('message', function (ev) {
  var data = ev.data;
  if (!data) return;

  if (data.transactionType === 'playSound') {
    audioPlayer.src = 'sounds/' + data.transactionFile + '.mp3';
    audioPlayer.volume = data.transactionVolume || 0.5;
    audioPlayer.play();
    return;
  }

  if (data.transactionType === 'stopSound') {
    audioPlayer.pause();
    audioPlayer.currentTime = 0;
    return;
  }

  if (data.ShowMenu === false || data.display === false) {
    hide();
    return;
  }

  if (data.display && !data.IsPauseMenuActive) {
    show(data.mode === 'restart' ? 'restart' : 'delcar', data.txtMin, data.txtSec);
  }
});
