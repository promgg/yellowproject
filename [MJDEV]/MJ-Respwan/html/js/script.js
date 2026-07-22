$(function () {
    // แสดง/ซ่อนแผงหน้าจอตาย
    function display(show) {
        document.getElementById('deathScreen').style.display = show ? 'flex' : 'none';
    }

    function pad(n) {
        n = parseInt(n, 10) || 0;
        return (n < 10 ? '0' : '') + n;
    }

    // เปิด/ปิดปุ่ม
    //   hideWhenOff = false -> ปิดแล้ว "โชว์อยู่แต่ทำจาง" (class disabled) เช่น RESPAWN ระหว่างนับถอยหลัง
    //   hideWhenOff = true  -> ปิดแล้ว "ซ่อนไปเลย" (class hidden) เช่น LEAVE ACTIVITY ตอนไม่อยู่ในกิจกรรม
    function setBtn(id, enabled, hideWhenOff) {
        var el = document.getElementById('btn-' + id);
        if (!el) return;
        var cls = hideWhenOff ? 'hidden' : 'disabled';
        if (enabled) {
            el.classList.remove(cls);
        } else {
            el.classList.add(cls);
        }
    }

    window.addEventListener('message', function (event) {
        var item = event.data || {};

        switch (item.type) {
            // แสดง/ซ่อน UI + ตั้งค่า Player ID
            case 'ui':
                display(item.status);
                if (item.status && item.id !== undefined) {
                    document.getElementById('PlayerId').textContent = item.id;
                }
                break;

            // นับถอยหลัง -> จัดรูปเป็น MM:SS
            case 'respawn':
                var m = item.minutes || 0;
                var s = item.seconds || 0;
                document.getElementById('timer').textContent = pad(m) + ':' + pad(s);
                break;

            // สถานะปุ่มทั้ง 5
            case 'buttons':
                setBtn('clearBody', item.clearBody);
                setBtn('respawn', item.respawn);                  // ปิด = จาง (โชว์อยู่)
                setBtn('leaveActivity', item.leaveActivity, true); // ปิด = ซ่อน
                setBtn('callHelp', item.callHelp);
                break;
        }
    });
});
