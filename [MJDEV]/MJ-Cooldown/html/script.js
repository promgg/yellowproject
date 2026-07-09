$(document).ready(function () {
    window.addEventListener('message', function(event) {
        var data = event.data;
        
        if (data.type == 'Show') {
            $('.container').fadeIn();

            // แปลงจากวินาทีเป็นนาทีและวินาที
            var minutes = Math.floor(data.time / 60); // คำนวณนาที
            var seconds = data.time % 60; // หาวินาทีที่เหลือ

            // รูปแบบผลลัพธ์เป็น "นาที:วินาที" ถ้าเวลา < 10 วินาที ให้เติม 0 ข้างหน้า
            var timeDisplay = minutes + ":" + (seconds < 10 ? "0" + seconds : seconds);

            $('#cooldown').html(timeDisplay); // แสดงผลลัพธ์
        } else if (data.type == 'Hide') {
            $('.container').fadeOut();
        }
    });
});
