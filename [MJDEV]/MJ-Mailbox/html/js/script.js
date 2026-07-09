let selectedItem = null;
let contacts = [];

window.addEventListener('message', function (event) {
    const data = event.data;
    switch (data.action) {
        case 'showUI':
            const container = document.querySelector('.container');
            if (container) {
                container.style.display = data.show ? 'block' : 'none';
            }
            if (data.show) refreshMessages(data.messages || []);
            break;
        case 'setCoords':
            const coords = data.coords;
            const coordsInput = document.querySelector('#send input[placeholder="พิกัด (ไม่บังคับ)"]');
            if (coordsInput) {
                coordsInput.value = coords;
            }
            break;
        case 'showMailIcon':
            document.getElementById("mailIcon").style.display = "block";
            updateMailCount(data.count);
            break;

        case 'receiveUserInfo':
            const userInfo = document.getElementById('userInfo');
            if (userInfo) {
                userInfo.innerHTML = `
                    ชื่อผู้ใช้: <strong>${data.firstname}</strong><br>
                    รหัสจดหมาย: <strong>#${data.mailCode}</strong>
                `;
            }
            break;
        case 'loadMessages':
            refreshMessages(data.messages);
            break;
        case 'showItems':
            const itemList = document.getElementById("itemList");
            itemList.innerHTML = "";
            data.items.forEach(item => {
                const btn = document.createElement("button");
                btn.textContent = `${item.label} (${item.count})`;
                btn.onclick = () => {
                    selectedItem = item;
                    document.getElementById("selectedItem").innerText = `🎁 แนบ: ${item.label}`;
                    closeItemPopup();
                };
                itemList.appendChild(btn);
            });
            document.getElementById("itemPopup").style.display = "block";
            break;

        case 'sendUserInfo':
            const infoDiv = document.getElementById("userInfo");
            if (data.data && data.data.name && data.data.mailCount !== undefined) {
                infoDiv.innerHTML = `
                    👤 ชื่อผู้ใช้: <strong>${data.data.name}</strong><br>
                    📬 จำนวนจดหมาย: <strong>${data.data.mailCount}</strong>
                `;
            }
            break;
        case 'loadContacts':
            const contactList = document.getElementById("contactList");
            contactList.innerHTML = "";

            if (data.contacts && data.contacts.length > 0) {
                data.contacts.forEach(contact => {
                    const contactEntry = document.createElement("div");
                    contactEntry.className = "contact-entry";
                    contactEntry.style.display = "flex";
                    contactEntry.style.justifyContent = "space-between";
                    contactEntry.style.alignItems = "center";
                    contactEntry.style.padding = "5px 10px";
                    contactEntry.style.borderBottom = "1px solid #ccc";

                    // 👤 ชื่อ + เบอร์
                    const nameEl = document.createElement("span");
                    nameEl.innerText = `${contact.name} (#${contact.contactId})`;
                    nameEl.style.cursor = "pointer";
                    nameEl.style.flex = "1";
                    nameEl.style.color = "white";
                    nameEl.addEventListener("click", () => {
                        openSendMessageModal(contact.name, contact.contactId);
                    });

                    // 🗑 ปุ่มลบ
                    const deleteBtn = document.createElement("button");
                    deleteBtn.innerText = "ลบ";
                    deleteBtn.style.background = "red";
                    deleteBtn.style.color = "white";
                    deleteBtn.style.border = "none";
                    deleteBtn.style.padding = "5px 10px";
                    deleteBtn.style.cursor = "pointer";
                    deleteBtn.addEventListener("click", () => {
                        deleteContact(contact.name);
                    });

                    contactEntry.appendChild(nameEl);
                    contactEntry.appendChild(deleteBtn);
                    contactList.appendChild(contactEntry);
                });
            } else {
                contactList.innerHTML = "<div class='contact-entry'>ไม่มีเพื่อนที่บันทึกไว้</div>";
            }
            break;
    }
});

function updateMailCount(count) {
    const wrapper = document.getElementById('mailIconWrapper');
    const badge = document.getElementById('mailCountBadge');
    const counter = document.getElementById("unread-counter");

    if (counter) {
        counter.textContent = count > 0 ? `(${count})` : '';
    }

    if (count > 0) {
        wrapper.style.display = 'block';
        badge.textContent = count;
    } else {
        wrapper.style.display = 'none';
    }
}


function deleteContact(name) {
    fetch(`https://MJ-Mailbox/deleteContact`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: name })
    }).then(() => {
        // reload รายชื่อใหม่
        fetchContacts();
    });
}

function openSendMessageModal(name, number) {
    Swal.fire({
        title: `ส่งข้อความถึง ${name} (${number})`,
        input: 'textarea',
        inputPlaceholder: 'พิมพ์ข้อความของคุณ...',
        showCancelButton: true,
        confirmButtonText: 'ส่ง',
        preConfirm: (message) => {
            if (!message) {
                Swal.showValidationMessage('กรุณาพิมพ์ข้อความก่อนส่ง');
                return false;
            }
            fetch(`https://MJ-Mailbox/sendMessage`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ recipientNumber: number, message: message })
            });
        }
    });
}

function fetchContacts() {
    fetch(`https://MJ-Mailbox/getContacts`, {
        method: 'POST'
    });
}


function openMessage(messageId) {
    const detailDiv = document.getElementById(`message-detail-${messageId}`);
    if (!detailDiv) return;

    // toggle แสดง/ซ่อน
    if (detailDiv.style.display === 'none') {
        detailDiv.style.display = 'block';

        // แจ้งเซิร์ฟเวอร์ว่าผู้ใช้เปิดอ่านข้อความนี้แล้ว
        $.post(`https://${GetParentResourceName()}/markAsRead`, JSON.stringify({ messageId }));

        // เปลี่ยนไอคอนสถานะอ่านเป็นสีเทา (อัพเดต UI ทันที)
        const summaries = document.getElementsByClassName('message-summary');
        for (let s of summaries) {
            // เปรียบเทียบ onclick attribute ให้ตรงกับ messageId
            if (s.getAttribute('onclick') === `openMessage(${messageId})`) {
                // ไอคอนสีแดง (ยังไม่อ่าน) เปลี่ยนเป็นสีเทา (อ่านแล้ว)
                const dotSpan = s.querySelector('span');
                if (dotSpan) {
                    dotSpan.style.color = '#888';
                    dotSpan.textContent = '●';  // จะเป็นสีเทาแทนสีแดง
                }
            }
        }
    } else {
        detailDiv.style.display = 'none';
    }
}


function closeItemPopup() {
    document.getElementById("itemPopup").style.display = "none";
}
function openItemSelector() {
    selectedItem = null;
    $.post(`https://${GetParentResourceName()}/getPlayerItems`);
}

function reply(friendName, messageId) {
    openPopup(friendName, messageId);
}

function openPopup(friendName = '', messageId = '') {
    showSection('send');
    const idInput = document.querySelector('#send input[placeholder="ใส่ ID ผู้รับ"]');
    const nameInput = document.querySelector('#send input[placeholder="ชื่อผู้รับ"]');
    if (idInput) idInput.value = messageId;
    if (nameInput) nameInput.value = friendName;
}


function getLocation() {
    $.post(`https://${GetParentResourceName()}/getPlayerCoords`);
}

function deleteMessage(id) {
    $.post(`https://${GetParentResourceName()}/deleteMessage`, JSON.stringify({ id }), function (response) {
        if (response && response.status) {
            $.post(`https://${GetParentResourceName()}/getMessages`, function (data) {
                if (data && data.messages) {
                    refreshMessages(data.messages);
                }
            });
        } else {
            Swal.fire('ลบข้อความไม่สำเร็จ!', '', 'warning');
        }
    });
}


function showSection(sectionId) {
    const sections = ["inbox", "contacts", "send"];
    sections.forEach(id => {
        const el = document.getElementById(id);
        if (el) el.style.display = (id === sectionId) ? "block" : "none";
    });
}

function refreshMessages(messages) {
    const inbox = document.getElementById('inbox');
    if (!messages || messages.length === 0) {
        inbox.innerHTML = `<p>ไม่มีข้อความในกล่องจดหมาย</p>`;
        return;
    }

    let html = '';

    messages.forEach(msg => {
        const isRead = msg.isRead === true;
        const readClass = isRead ? 'read' : 'unread'; // กำหนดคลาสตามสถานะ
        const readIcon = `<span style="color:${isRead ? '#888' : 'red'}; font-size:18px; margin-right:5px;">●</span>`;

        html += `
            <div class="message-summary ${readClass}" style="cursor:pointer; border-bottom:1px solid #ccc; padding:8px;" onclick="openMessage(${msg.id})" title="คลิกเพื่ออ่านข้อความ">
                ${readIcon}
                <strong>${escapeHtml(msg.sender)}</strong> - <em>${escapeHtml(msg.subject || '(ไม่มีหัวข้อ)')}</em><br>
                <small style="color:#aaa;">📩 เลข: #${msg.mailID}</small>
                <small style="color:#666;">ส่งเมื่อ: ${escapeHtml(msg.timestamp)}</small><br>
            </div>
            <div id="message-detail-${msg.id}" class="message-detail" style="display:none; padding:8px 16px; background:#0e0d0dd7;">
                <p>${escapeHtml(msg.message || '')}</p>
                ${msg.item ? `<p>🎁 ไอเท็มแนบ: ${escapeHtml(msg.item.label)}</p>` : ''}
                ${msg.coords ? `<p><span style="cursor:pointer; color:green; text-decoration:underline;" onclick="sendCoords('${msg.coords}')">📍 พิกัด: ${msg.coords}</span></p>` : ''}
                ${msg.image_url ? `<p><a href="${escapeHtml(msg.image_url)}" target="_blank" rel="noopener noreferrer">ดูรูปภาพ</a></p>` : ''}
                <button onclick="reply('${escapeHtml(msg.sender)}', '${escapeHtml(msg.mailID)}')">ตอบกลับ</button>
                <button onclick="deleteMessage(${msg.id})" style="background-color:#a00; color:#fff;">ลบ</button>
            </div>
        `;
    });

    inbox.innerHTML = html;
}

function renderContacts() {
    const listDiv = document.getElementById('contactList');
    listDiv.innerHTML = ''; // เคลียร์ก่อน render ใหม่

    contacts.forEach(contact => {
        const contactElement = document.createElement('div');
        contactElement.className = 'contact-item';
        contactElement.textContent = `${contact.name} (${contact.contactId})`;
        listDiv.appendChild(contactElement);
    });
}

function closePopup() {
    // ซ่อน section ส่งข้อความ
    const sendSection = document.getElementById('send');
    if (sendSection) {
        sendSection.style.display = 'none';
    }

    // เคลียร์ค่าใน input และ textarea
    const inputs = sendSection.querySelectorAll('input, textarea');
    inputs.forEach(input => input.value = '');

    // เคลียร์ selected item ที่แนบถ้ามี
    selectedItem = null;
    const selectedItemLabel = document.getElementById("selectedItem");
    if (selectedItemLabel) {
        selectedItemLabel.innerText = '';
    }
}

// แยกค่าพิกัดเป็น object
function parseCoords(str) {
    const regex = /X:([-+]?\d*\.?\d+)\s+Y:([-+]?\d*\.?\d+)\s+Z:([-+]?\d*\.?\d+)/;
    const match = str.match(regex);
    if (!match) return null;

    return {
        x: parseFloat(match[1]),
        y: parseFloat(match[2]),
        z: parseFloat(match[3]),
    };
}

function sendCoords(coordString) {
    const coords = parseCoords(coordString);
    if (!coords) {
        console.error("พิกัดไม่ถูกต้อง:", coordString);
        return;
    }

    // ส่งข้อมูลพิกัดในรูปแบบ JSON (ใช้ coords ที่แปลงได้)
    fetch(`https://${GetParentResourceName()}/sendCoords`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            coords: {
                x: coords.x,
                y: coords.y,
                z: coords.z
            }
        })
    })
}

function loadContactsFromServer() {
    $.post(`https://${GetParentResourceName()}/getContacts`, JSON.stringify({}), function (data) {
        contacts = data || [];
        renderContacts();
    });
}


$(document).ready(function () {
    window.showSection = function (sectionId) {
        $('.section').removeClass('active');
        $('#' + sectionId).addClass('active');
    };

    let selectedItem = null; // global for selected item attachment

    // Send message from "Send" section
    $('#sendBtn').click(function () {
        // Collect input values
        let receiverId = $('#send input[placeholder="ใส่ ID ผู้รับ"]').val().trim();
        let receiverName = $('#send input[placeholder="ชื่อผู้รับ"]').val().trim();
        let subject = $('#mailSubject').val().trim();
        let message = $('#send textarea').val().trim();
        let imageUrl = $('#send input[placeholder="URL รูป (ไม่บังคับ)"]').val().trim() || null;
        let coords = $('#send input[placeholder="พิกัด (ไม่บังคับ)"]').val().trim() || null;

        if (!receiverId || !receiverName || !message) {
            Swal.fire('กรุณากรอกข้อมูลให้ครบ', '', 'warning');
            return;
        }

        $.post(`https://${GetParentResourceName()}/sendMessage`, JSON.stringify({
            receiverId,
            receiverName,
            subject,
            message,
            image_url: imageUrl,
            coords,
            item: selectedItem
        }), function (response) {
            if (response && response.success) {
                Swal.fire('ส่งข้อความสำเร็จ', '', 'success');
                closePopup();
                refreshMessages(response.messages);
            }
        });
    });


    // Close UI button
    $('#closeButton').click(function () {
        document.querySelector('.container').style.display = 'none';
        $.post(`https://${GetParentResourceName()}/closeUI`);
    });

});


// ปุ่ม Escape ปิด UI
document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
        document.querySelector('.container').style.display = 'none';
        $.post(`https://${GetParentResourceName()}/closeUI`);
    }
});

function closeAddContactPopup() {
    const popup = document.getElementById('addContactPopup');
    popup.style.display = 'none';
    document.getElementById('contactName').value = '';
    document.getElementById('contactId').value = '';
}

document.addEventListener('DOMContentLoaded', () => {
    const popup = document.getElementById('addContactPopup');
    const openBtn = document.getElementById('openAddContactBtn');
    if (openBtn && popup) {
        openBtn.addEventListener('click', () => {
            popup.style.display = 'block';
        });
    }

    // ปุ่มปิด popup
    const btnClose = document.getElementById('btnCloseAddContactPopup');
    if (btnClose) {
        btnClose.addEventListener('click', () => {
            popup.style.display = 'none';
            document.getElementById('contactName').value = '';
            document.getElementById('contactID').value = '';
        });
    }

    // ปุ่มเพิ่มรายชื่อ
    const btnAdd = document.getElementById('btnAddContact');
    if (btnAdd) {
        btnAdd.addEventListener('click', () => {
            const name = document.getElementById('contactName').value.trim();
            const Id = document.getElementById('contactId').value.trim();

            if (name === '' || Id === '') {
                Swal.fire('กรุณากรอกข้อมูลให้ครบ!', '', 'warning');
                return;
            }

            $.post(`https://${GetParentResourceName()}/addContact`,
                JSON.stringify({ name: name, contactId: Id }),
                function () {
                    Swal.fire('เพิ่มรายชื่อสำเร็จ!', '', 'success');
                    popup.style.display = 'none';
                    document.getElementById('contactName').value = '';
                    document.getElementById('contactID').value = '';
                    contacts.push({ name, Id });
                    renderContacts();
                    closeAddContactPopup();
                }
            );
        });
    }
});

function escapeHtml(text) {
    if (!text) return '';
    return text.replace(/[&<>"']/g, function (match) {
        const escape = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;',
        };
        return escape[match];
    });
}
