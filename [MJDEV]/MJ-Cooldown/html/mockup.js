(function () {
    var notes = {
        ember: 'แดงเฉพาะสัญลักษณ์บาดเจ็บและใช้ทองกับเวลา อ่านง่ายและเข้าชุดกับ lp_textui มากที่สุด',
        blood: 'โทนแดงสนิมเด่นขึ้น สื่ออาการบาดเจ็บชัด แต่จะดึงสายตามากกว่าเมื่อแสดงค้างนาน',
        bone: 'โทนกระดูกและทองเหลืองนุ่มที่สุด กลืนกับ HUD ดี แต่ความเร่งด่วนของสถานะจะลดลง'
    };
    var tabs = Array.prototype.slice.call(document.querySelectorAll('.design-tab'));
    var slider = document.getElementById('timeSlider');
    var output = document.getElementById('timeOutput');
    var note = document.getElementById('designNote');

    function pad(value) { return value < 10 ? '0' + value : String(value); }

    function updateTime() {
        var seconds = Number(slider.value);
        var display = '00:' + pad(seconds);
        var ratio = seconds / Number(slider.max);
        output.textContent = display;
        document.querySelectorAll('.js-time').forEach(function (el) { el.textContent = display; });
        document.querySelectorAll('.js-progress').forEach(function (el) { el.style.width = (ratio * 100) + '%'; });
        document.querySelectorAll('.js-ring').forEach(function (el) { el.style.strokeDashoffset = String(125.66 * (1 - ratio)); });
    }

    tabs.forEach(function (tab) {
        tab.addEventListener('click', function () {
            var theme = tab.dataset.theme;
            document.body.dataset.theme = theme;
            tabs.forEach(function (item) { item.classList.toggle('active', item === tab); });
            note.textContent = notes[theme];
        });
    });
    slider.addEventListener('input', updateTime);
    updateTime();
}());
