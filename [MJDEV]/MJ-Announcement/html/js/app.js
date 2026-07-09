let queue = [];
let maxQueue = 0;
let isSetup = false;

$(document).ready(function() {
    const onReceive = (text, duration, picture, color) => {
        const queueId = queue.length + 1;

        // ตรวจสอบว่าภาพมีอยู่จริง
        const imgSrc = `./images/${picture}`;

        queue.push({ id: queueId, picture, text });

        $('.container').append(`
            <div class="card" qid="${queueId}">
                <div class="decor" style="background: ${color};">
                    <div class="logo">
                        <img src="${imgSrc}" alt="${picture}">
                    </div>
                </div>
                <div class="text">${text}</div>
            </div>
        `);

        // ตั้งเวลาในการแสดงผล
        setTimeout(() => {
            const $card = $(`.card[qid=${queueId}]`);
            $card.find('.text').html("")
            $card.find('.text').addClass('end');
            $card.addClass('end');
            $card.find('.decor').fadeOut();

            setTimeout(() => {
                removeArrayFromId(queueId);
                $card.remove();
            }, 1500);
        }, duration);
    };

    const removeArrayFromId = (id) => {
        queue = queue.filter((value) => value.id !== id);
    };

    window.addEventListener('message', (event) => {
        const item = event.data;

        switch (item.action) {
            case 'onSetupConfig':
                maxQueue = item.maximum;
                isSetup = true;
                break;
            case 'onReceive':
                // ตรวจสอบค่าก่อนเรียกใช้งาน onReceive
                if (typeof item.text !== 'string' || !item.text) {
                    console.error('Invalid text received:', item.text);
                    return;
                }
                if (queue.length >= maxQueue || !isSetup) return;
                onReceive(item.text, item.duration || 12000, item.pic || 'default.png', item.color || '#ffffff');
                break;
        }
    });
});