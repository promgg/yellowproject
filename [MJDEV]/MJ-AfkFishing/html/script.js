document.addEventListener('DOMContentLoaded', function () {
    // อ้างอิง UI องค์ประกอบต่างๆ
    const afkUI = document.getElementById("afkUI");
    const itemImage = document.getElementById("itemImage");
    const progressBarAFK = document.getElementById("progressBarAFK");
    const progressText = document.getElementById("progressText");
    const cooldownTime = document.getElementById("cooldownTime");      

    let totalSeconds = 0;
    let intervalId;  // ตัวแปรสำหรับเก็บ ID ของ setInterval เพื่อหยุดการทำงานเมื่อมีการเปลี่ยนแปลง

    window.addEventListener('message', function (event) {
        const item = event.data;

        if (item.type === "showMessage") {
            // แสดงข้อความ AFK
            const messageElement = document.getElementById('afkMessage');
            if (messageElement) {
                messageElement.style.display = "block"; // แสดงข้อความ
                messageElement.textContent = item.message; // อัปเดตข้อความ
            }
        } else if (item.type === "hideMessage") {
            // ซ่อนข้อความ AFK
            const messageElement = document.getElementById('afkMessage');
            if (messageElement) {
                messageElement.style.display = "none"; // ซ่อนข้อความ
            }
        }

        if (item.type === "updateUI" && item.victims !== undefined && item.progress !== undefined) {
            // อัปเดตข้อความจำนวนเหยื่อ
            const progressBar = document.getElementById('progressBar');
            const progressPercent = document.getElementById('progressPercent');
            const infoText = document.getElementById('infoText');

            if (infoText && progressBar && progressPercent) {
                // อัปเดตจำนวนเหยื่อ
                infoText.textContent = `จำนวนเหยื่อ: ${item.victims}`;

                // คำนวณเปอร์เซ็นต์และอัปเดต progress bar
                let progress = Math.min(Math.max(item.progress, 0), 100); // จำกัดค่าระหว่าง 0 ถึง 100
                progressBar.style.width = `${progress}%`; // กำหนดความกว้างของ progress bar
                progressPercent.textContent = `${progress}%`; // แสดงเปอร์เซ็นต์ที่กลาง progress bar
                updateUI(item.image, progress)

                // เมื่อ progress bar ถึง 100%
                if (progress === 100) {
                    // ตั้งเวลาให้รีเซ็ต progress bar
                    setTimeout(() => {
                        progressBar.style.width = "0%"; // รีเซ็ตความกว้างของ progress bar
                        progressPercent.textContent = "0%"; // รีเซ็ตเปอร์เซ็นต์
                        infoText.textContent = "โหลดเสร็จแล้ว!"; // อัปเดตข้อความ
                    }, 1000); // รอ 1 วินาทีหลังจาก progress ถึง 100%
                }
            }
        }

        // แสดงและซ่อน UI ตามประเภท
        if (item.type === "showUI") {
            const uiContainer = document.getElementById('ui-container');
            if (uiContainer) {
                uiContainer.style.display = "block"; // แสดง UI
                afkUI.style.display = "block";
                startTimer(); // เริ่มการนับเวลา
            }
        } else if (item.type === "hideUI") {
            const uiContainer = document.getElementById('ui-container');
            if (uiContainer) {
                uiContainer.style.display = "none"; // ซ่อน UI
                afkUI.style.display = "none";
                totalSeconds = 0;
                clearInterval(intervalId); // หยุดการนับเวลาเมื่อปิด UI
            }
        } else if (item.type === "showafk") {
            afkUI.style.display = "block";
        } else if (item.type === "hideafk") {
            afkUI.style.display = "none";
        }
    });

    function startTimer() {
        if (intervalId) {
            clearInterval(intervalId); // หยุดการทำงานของ setInterval เดิม
        }

        intervalId = setInterval(() => {
            totalSeconds++;
            const minutes = Math.floor(totalSeconds / 60);
            const seconds = totalSeconds % 60;
            cooldownTime.textContent = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
        }, 1000); // นับทุก 1 วินาที
    }

    // ฟังก์ชันอัปเดต UI แบบวงกลม
    function updateUI(itemURL, progress) {
        if (itemImage && progressBarAFK) {
            itemImage.src = `nui://vorp_inventory/html/img/items/${itemURL}.png`;  // อัปเดต URL ของรูปภาพ

            // คำนวณ stroke-dashoffset ตามเปอร์เซ็นต์
            const offset = 440 - (440 * progress / 100);
            const progressCircle = document.getElementById('progressCircle');
            if (progressCircle) {
                progressCircle.style.strokeDashoffset = offset; // ปรับค่า strokeDashoffset เพื่อเปลี่ยนความคืบหน้าในวงกลม
            }

            // อัปเดตข้อความ progress
            progressText.textContent = `${progress}%`;
        }
    }

});
