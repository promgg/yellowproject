/* lp_rewardpanel NUI — app.js */
'use strict';

(function () {
  var panel   = document.getElementById('drop-panel');
  var titleEl = document.getElementById('dp-title');
  var labelEl = document.getElementById('dp-label');
  var dpSlots = document.getElementById('dp-slots');

  var SLOT_COUNT = 8;
  var currentItems = [];

  function buildSlots(items) {
    dpSlots.innerHTML = '';
    for (var i = 0; i < SLOT_COUNT; i++) {
      var slot = document.createElement('div');
      slot.className = 'dp-slot';
      if (items && items[i]) {
        slot.classList.add('has-item');
        var img = document.createElement('img');
        img.src = items[i].img || '';
        img.alt = '';
        img.onerror = function () { this.style.display = 'none'; };
        slot.appendChild(img);
        if (items[i].chance) {
          var lbl = document.createElement('span');
          lbl.className = 'dp-slot-label';
          lbl.textContent = items[i].chance + '%';
          slot.appendChild(lbl);
        }
      }
      dpSlots.appendChild(slot);
    }
  }

  function show(d) {
    currentItems = d.items || [];
    titleEl.textContent = d.title || 'โอกาสดร็อป';
    labelEl.textContent = d.subtitle || 'Reward Drop Info';
    buildSlots(currentItems);
    panel.classList.remove('hidden');
  }

  function hide() {
    panel.classList.add('hidden');
  }

  function highlight(item) {
    var slots = dpSlots.querySelectorAll('.dp-slot');
    slots.forEach(function (s) { s.classList.remove('active'); });
    for (var i = 0; i < currentItems.length; i++) {
      if (currentItems[i] && currentItems[i].item === item && slots[i]) {
        slots[i].classList.add('active');
        setTimeout(function (el) { el.classList.remove('active'); }, 3000, slots[i]);
        break;
      }
    }
  }

  window.addEventListener('message', function (ev) {
    var d = ev.data || {};
    switch (d.action) {
      case 'lp_rewardpanel:show':      show(d); break;
      case 'lp_rewardpanel:hide':      hide(); break;
      case 'lp_rewardpanel:highlight': highlight(d.item); break;
    }
  });

  // ── Mock for browser dev (no game backend) ────────────────────────────
  if (typeof GetParentResourceName !== 'function') {
    window.__lpRewardPanelMock = {
      show: function (items, title, subtitle) {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_rewardpanel:show', items: items, title: title, subtitle: subtitle } }));
      },
      hide: function () {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_rewardpanel:hide' } }));
      },
      highlight: function (item) {
        window.dispatchEvent(new MessageEvent('message', { data: { action: 'lp_rewardpanel:highlight', item: item } }));
      },
    };
  }
})();
