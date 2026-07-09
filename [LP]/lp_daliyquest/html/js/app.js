/* Dailyquest NUI — app.js */
'use strict';

var root = document.getElementById('root');
var list = document.getElementById('quest-list');
var hint = document.getElementById('qp-hint');

function buildList(quests) {
  list.innerHTML = '';
  quests.forEach(function(q) {
    var done = q.current >= q.target;
    var row  = document.createElement('div');
    row.className = 'quest-row';

    var iconBox = document.createElement('div');
    iconBox.className = 'quest-icon-box';
    var img = document.createElement('img');
    img.src = q.img || '';
    img.alt = '';
    img.onerror = function() { this.style.display = 'none'; };
    iconBox.appendChild(img);

    var textArea = document.createElement('div');
    textArea.className = 'quest-text';
    textArea.innerHTML =
      '<div class="quest-top">' +
        '<span class="quest-progress' + (done ? ' done' : '') + '">' + q.current + '/' + q.target + '</span>' +
        '<p class="quest-name">' + (q.name || '') + '</p>' +
      '</div>' +
      '<p class="quest-desc">' + (q.desc || '') + '</p>';

    row.appendChild(iconBox);
    row.appendChild(textArea);
    list.appendChild(row);
  });
}

window.addEventListener('message', function(ev) {
  var data = ev.data;
  if (!data || !data.action) return;

  if (data.action === 'openQuest') {
    // Phase 2 low: อัปเดต hint text จาก Config.ToggleCommand แทน hard-code
    if (data.toggleCmd && hint) {
      hint.textContent = '[/' + data.toggleCmd + ' เพื่อซ่อนเมนูเควส]';
    }
    if (data.quests) buildList(data.quests);
    root.classList.remove('hidden');
  } else if (data.action === 'closeQuest') {
    root.classList.add('hidden');
  } else if (data.action === 'updateQuest') {
    if (data.quests) buildList(data.quests);
  }
  // Phase 5: ลบ toggleQuest dead handler ออกแล้ว
});
