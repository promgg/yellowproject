const dutyUI = document.getElementById('duty-ui');
const img = document.getElementById('img');
const textduty = document.getElementById('textduty');
const dutyToggleBtn = document.getElementById('duty-toggle');
const checkBtn = document.getElementById('checktime');
const modalBg = document.getElementById('modal-time');
const modalText = document.getElementById('modal-text');
const modalCloseBtn = document.getElementById('modal-close');

let inDuty = false; // เก็บสถานะใน UI
let currentId = null;
let currentJob = null;
let currentOffJob = null;

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === 'open') {
        img.src = data.img || '';
        textduty.textContent = data.text || '';
        dutyUI.style.display = 'flex';

        inDuty = !!data.induty;
        dutyToggleBtn.textContent = inDuty ? 'ออกเวร' : 'เข้าเวร';

        currentId = data.id || null;
        currentJob = data.injob || null;
        currentOffJob = data.offjob || null;
    }
    else if (data.action === 'close') {
        dutyUI.style.display = 'none';
        hideModal();
        inDuty = false;
        currentId = null;
        currentJob = null;
        currentOffJob = null;
    }
});

dutyToggleBtn.addEventListener('click', () => {
    if (inDuty) {
        fetch(`https://${GetParentResourceName()}/offduty`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                id: currentId,
                offjob: currentOffJob
            })
        });
        inDuty = false;
        dutyToggleBtn.textContent = 'เข้าเวร';
    } else {
        fetch(`https://${GetParentResourceName()}/joinduty`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                id: currentId,
                Job: currentJob
            })
        });
        inDuty = true;
        dutyToggleBtn.textContent = 'ออกเวร';
    }
});


checkBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/checktime`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(data => {
        if (data.hours && data.minutes && data.seconds) {
            modalText.textContent = `เวลาที่เข้าเวร: ${data.hours}:${data.minutes}:${data.seconds}`;
        } else {
            modalText.textContent = `คุณยังไม่ได้เข้าเวร`;
        }
        showModal();
    });
});

modalCloseBtn.addEventListener('click', () => {
    hideModal();
});

function showModal() {
    modalBg.style.display = 'flex';
}
function hideModal() {
    modalBg.style.display = 'none';
}

$(document).ready(function () {
    // ปิด modal popup
    $('#modal-close').click(function () {
        $('#modal-time').fadeOut();
    });

    // ปุ่มปิด UI หลัก (ซ่อน div #duty-ui)
    $('#close-ui').click(function () {
        $('#duty-ui').fadeOut();
        $.post(`https://${GetParentResourceName()}/close`, JSON.stringify({}));
    });

});
