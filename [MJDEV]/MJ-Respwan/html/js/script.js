(function () {
    var screenEl = document.getElementById('deathScreen');

    function display(show) {
        screenEl.classList.toggle('show', !!show);
    }

    function pad(n) {
        n = parseInt(n, 10) || 0;
        return (n < 10 ? '0' : '') + n;
    }

    function btnEl(id) {
        return document.getElementById('btn-' + id);
    }

    function fillEl(id) {
        var b = btnEl(id);
        return b ? b.querySelector('.lt-fill') : null;
    }

    // เปิด/ปิดปุ่ม
    //   hideWhenOff = false -> ปิดแล้วโชว์อยู่แต่ทำจาง (is-dim) เช่น RESPAWN ระหว่างนับถอยหลัง
    //   hideWhenOff = true  -> ปิดแล้วซ่อนไปเลย (is-hide) เช่น LEAVE ACTIVITY ตอนไม่อยู่ในกิจกรรม
    function setBtn(id, enabled, hideWhenOff) {
        var el = btnEl(id);
        if (!el) return;
        var cls = hideWhenOff ? 'is-hide' : 'is-dim';
        el.classList.toggle(cls, !enabled);
    }

    // ===== hold fill (เหมือน lp_textui: CSS transition scaleX ล้วน) =====
    function startFill(id, duration) {
        var f = fillEl(id);
        if (!f) return;
        f.style.transition = 'none';
        f.style.transform = 'scaleX(0)';
        f.getBoundingClientRect();               // force reflow ให้จำค่าเริ่มต้น
        f.style.transition = 'transform ' + duration + 'ms linear';
        f.style.transform = 'scaleX(1)';
    }

    function doneFill(id) {
        var f = fillEl(id);
        if (!f) return;
        f.style.transition = 'none';
        f.style.transform = 'scaleX(1)';
    }

    function cancelFill(id) {
        var f = fillEl(id);
        if (!f) return;
        f.style.transition = 'transform 120ms ease-out';
        f.style.transform = 'scaleX(0)';
    }

    function resetAllFills() {
        ['clearBody', 'respawn', 'leaveActivity', 'callHelp'].forEach(function (id) {
            var f = fillEl(id);
            if (f) { f.style.transition = 'none'; f.style.transform = 'scaleX(0)'; }
        });
    }

    window.addEventListener('message', function (event) {
        var item = event.data || {};

        switch (item.type) {
            // แสดง/ซ่อน UI + ตั้งค่า Player ID
            case 'ui':
                display(item.status);
                if (item.status) {
                    resetAllFills();
                    if (item.id !== undefined) {
                        document.getElementById('PlayerId').textContent = item.id;
                    }
                }
                break;

            // นับถอยหลัง -> จัดรูปเป็น MM:SS
            case 'respawn':
                document.getElementById('timer').textContent = pad(item.minutes || 0) + ':' + pad(item.seconds || 0);
                break;

            // สถานะปุ่ม
            case 'buttons':
                setBtn('clearBody', item.clearBody, true);          // ปิด = ซ่อน (ยังไม่เปิดใช้)
                setBtn('respawn', item.respawn);                    // ปิด = จาง (โชว์อยู่)
                setBtn('leaveActivity', item.leaveActivity, true);  // ปิด = ซ่อน
                setBtn('callHelp', item.callHelp, true);            // ปิด = ซ่อน (ยังไม่เปิดใช้)
                break;

            // กดค้าง: start (เริ่มไล่ fill), done (เต็ม), cancel (ปล่อยก่อน = ถอย)
            case 'hold':
                if (item.state === 'start') startFill(item.id, item.duration || 600);
                else if (item.state === 'done') doneFill(item.id);
                else cancelFill(item.id);
                break;
        }
    });
})();
