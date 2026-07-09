var _resourceName = (function() {
  try { return window.GetParentResourceName(); } catch(e) { return 'MJ-CodeReward'; }
})();

// ── NUI Messages จาก client.lua ──
window.addEventListener('message', function(event) {
  var type = event.data && event.data.type;
  if      (type === 'openPlayerUI')  openUI('playerPanel');
  else if (type === 'openAdminUI')   openUI('adminPanel');
  else if (type === 'closePlayerUI') closeUI('playerPanel');
});

// ── Open / Close ──

function openUI(panelId) {
  document.getElementById('app').classList.remove('hidden');
  document.getElementById(panelId).classList.remove('hidden');
  if (panelId === 'playerPanel') {
    clearFeedback();
    setTimeout(function() { document.getElementById('playerCode').focus(); }, 50);
  }
}

function closeUI(panelId) {
  document.getElementById(panelId).classList.add('hidden');
  var anyOpen = ['playerPanel', 'adminPanel'].some(function(id) {
    return !document.getElementById(id).classList.contains('hidden');
  });
  if (!anyOpen) document.getElementById('app').classList.add('hidden');
  fetch('https://' + _resourceName + '/closeCode', { method: 'POST' }).catch(function(){});
}

function clearFeedback() {
  document.getElementById('playerCode').value = '';
}

// ── Redeem ──

var _redeemLock = false;

function redeemCode() {
  if (_redeemLock) return;
  var inp  = document.getElementById('playerCode');
  var code = inp.value.trim();
  if (!code) return;

  _redeemLock = true;
  setTimeout(function() { _redeemLock = false; }, 3000);

  fetch('https://' + _resourceName + '/redeemCode', {
    method: 'POST',
    body: JSON.stringify({ code: code }),
    headers: { 'Content-Type': 'application/json' }
  }).catch(function() { _redeemLock = false; });
}

document.addEventListener('DOMContentLoaded', function() {
  document.getElementById('playerCode').addEventListener('keydown', function(e) {
    if (e.key === 'Enter')  redeemCode();
    if (e.key === 'Escape') closeUI('playerPanel');
  });
});

// ── Admin ──

var usedCodes = [];

function generateCode() {
  var newCode;
  var attempts = 0;
  do {
    newCode = 'MJ-' + Math.random().toString(36).substring(2, 6).toUpperCase() + '-' + Math.floor(Math.random() * 10000);
    attempts++;
  } while (usedCodes.includes(newCode) && attempts < 10);

  document.getElementById('generatedCode').textContent = newCode;

  fetch('https://' + _resourceName + '/getRandomCode', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ newCode: newCode })
  })
  .then(function(res) { return res.json(); })
  .then(function(data) {
    if (data.success) {
      usedCodes.push(newCode);
      var container = document.getElementById('codeContainer');
      container.innerHTML = '';
      var btn = document.createElement('button');
      btn.textContent = 'Copy Code';
      btn.className = 'btn-copy';
      btn.onclick = function() {
        navigator.clipboard.writeText(newCode).catch(function() {
          var tmp = document.createElement('textarea');
          tmp.value = newCode;
          document.body.appendChild(tmp);
          tmp.select();
          document.execCommand('copy');
          document.body.removeChild(tmp);
        });
      };
      container.appendChild(btn);
    }
  })
  .catch(function() {});
}
