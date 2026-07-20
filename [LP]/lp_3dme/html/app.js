/* lp_3dme — วาดกล่องข้อความตามพิกัดจอที่ Lua ส่งมา
 *
 * ⚠️ ข้อความของผู้เล่นถูกใส่ด้วย textContent เท่านั้น ห้ามใช้ innerHTML กับมันเด็ดขาด
 *    ถ้าเผลอใช้ innerHTML ผู้เล่นพิมพ์ <img src=x onerror="..."> แล้วรันโค้ดในเครื่อง
 *    ของทุกคนที่มองเห็นข้อความนั้นได้
 */
(function () {
  'use strict';

  var stage = document.getElementById('stage');
  var nodes = {}; // key -> { el, labelEl, textEl }

  function makeBubble() {
    var el = document.createElement('div');
    el.className = 'bubble';

    var label = document.createElement('span');
    label.className = 'label';

    var text = document.createElement('span');
    text.className = 'text';

    el.appendChild(label);
    el.appendChild(text);

    return { el: el, labelEl: label, textEl: text };
  }

  function render(items) {
    var seen = {};

    // เรียงให้คนไกลวาดก่อน คนใกล้จะได้ทับอยู่ด้านหน้า
    items.sort(function (a, b) {
      return b.dist - a.dist;
    });

    items.forEach(function (item, index) {
      seen[item.key] = true;

      var node = nodes[item.key];
      if (!node) {
        node = makeBubble();
        nodes[item.key] = node;
        stage.appendChild(node.el);
      }

      // label ว่าง = ไม่ต้องแสดงส่วนนำหน้า
      if (item.label) {
        node.labelEl.textContent = item.label + ':';
        node.labelEl.style.color = item.color || '#fff';
        node.labelEl.style.display = '';
      } else {
        node.labelEl.style.display = 'none';
      }

      // textContent เท่านั้น — เบราว์เซอร์จะ escape ให้เอง แท็กที่ผู้เล่นพิมพ์
      // จะกลายเป็นตัวอักษรธรรมดา ไม่ใช่ DOM
      node.textEl.textContent = item.text;

      // เลื่อนด้วย transform ล้วน (ดูเหตุผลใน style.css) — translate ตัวหลังคิด %
      // จากขนาดของกล่องเอง จึงได้จุดยึดเป็นกึ่งกลางล่างตามต้องการ
      node.px = (item.x / 100) * window.innerWidth;
      node.py = (item.y / 100) * window.innerHeight;
      node.el.style.transform =
        'translate(' + node.px + 'px, ' + node.py + 'px) translate(-50%, -100%)';
      node.el.style.zIndex = String(1000 + index);
    });

    // หนีบกล่องไม่ให้ทะลุขอบจอ
    // ต้องทำหลังวางตำแหน่งครบทุกใบ เพราะ getBoundingClientRect บังคับ layout —
    // ถ้าวัดสลับกับการเขียน style ทีละใบจะเกิด reflow ซ้ำๆ ทุกใบ (layout thrashing)
    var PAD = 6;
    items.forEach(function (item) {
      var node = nodes[item.key];
      if (!node) return;

      var r = node.el.getBoundingClientRect();
      var dx = 0, dy = 0;

      if (r.left < PAD) dx = PAD - r.left;
      else if (r.right > window.innerWidth - PAD) dx = (window.innerWidth - PAD) - r.right;

      if (r.top < PAD) dy = PAD - r.top;
      else if (r.bottom > window.innerHeight - PAD) dy = (window.innerHeight - PAD) - r.bottom;

      if (dx !== 0 || dy !== 0) {
        node.el.style.transform =
          'translate(' + (node.px + dx) + 'px, ' + (node.py + dy) + 'px) translate(-50%, -100%)';
      }
    });

    // เก็บกวาดกล่องที่ไม่ได้ส่งมาในรอบนี้แล้ว
    Object.keys(nodes).forEach(function (key) {
      if (!seen[key]) {
        var node = nodes[key];
        if (node.el.parentNode) {
          node.el.parentNode.removeChild(node.el);
        }
        delete nodes[key];
      }
    });
  }

  window.addEventListener('message', function (event) {
    var data = event.data || {};
    if (data.action === 'update') {
      render(data.items || []);
    }
  });

  /* ---- ทดสอบในเบราว์เซอร์ (ไม่มีผลในเกม) ----
     เปิดหน้านี้ผ่าน dev server แล้วเรียก preview() ใน console */
  window.preview = function () {
    render([
      { key: 'a', x: 50, y: 34, label: 'ME', color: '#6ddb51', dist: 3,
        text: 'เขียนชื่อรับไปรษณีย์ ของตัวเองลงกระดาษ เขียนว่า PHUN CHOOCHUAY และส่งให้แม่นาง' },
      { key: 'b', x: 26, y: 55, label: 'DO', color: '#4d66f1', dist: 8,
        text: 'กระดาษเปียกน้ำจนหมึกเลอะ' },
      { key: 'c', x: 74, y: 48, label: 'OOC', color: '#808080', dist: 6,
        text: 'ขอตัวสักครู่นะครับ' },
      { key: 'd', x: 50, y: 70, label: 'DICE', color: '#A52A2A', dist: 5,
        text: 'ทอย 2d6 ได้ 4 + 3 = 7' },
      { key: 'e', x: 18, y: 28, label: 'DESC', color: '#c9a227', dist: 11,
        text: 'มีแผลเป็นยาวพาดที่แก้มซ้าย' },
      { key: 'f', x: 82, y: 22, label: 'ROLL', color: '#FFFF00', dist: 13,
        text: 'สุ่มได้ 87 / 100' }
    ]);
  };

  // เปิดในเบราว์เซอร์ธรรมดา (ไม่ใช่ NUI) ให้โชว์ตัวอย่างเลย
  if (typeof window.GetParentResourceName !== 'function') {
    document.body.style.background = '#1a1a1a';
    window.addEventListener('load', window.preview);
  }
})();
