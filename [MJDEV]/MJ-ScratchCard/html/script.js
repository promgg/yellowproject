document.addEventListener("DOMContentLoaded", function () {
    const scratchSound = new Audio("./sounds/scratch.mp3");
    scratchSound.volume = 0.5; // ปรับระดับเสียง    
    const rewardSound = new Audio("./sounds/reward.mp3");
    rewardSound.volume = 0.7; // ปรับระดับเสียง
    const canvas = document.getElementById("scratchCanvas");
    const ctx = canvas.getContext("2d");
    const rewardImage = document.getElementById("rewardImage");
    const container = document.querySelector(".scratch-container");
    let imgPath = 'nui://vorp_inventory/html/img/items/';
    let isDrawing = false;
    let lastX, lastY;
    let scratchProgress = 0;
    let rewardGiven = false;
    let selectedReward = null; // เก็บค่าของรางวัลที่สุ่มได้

    function resizeCanvas() {
        canvas.width = container.clientWidth;
        canvas.height = container.clientHeight;

        const scratchImage = new Image();
        scratchImage.src = "./img/scratch_overlay.png";

        scratchImage.onload = function () {
            ctx.globalCompositeOperation = "source-over";
            ctx.drawImage(scratchImage, 0, 0, canvas.width, canvas.height);
            ctx.globalCompositeOperation = "destination-out";
        };

        // สุ่มรางวัลตั้งแต่ต้น และแสดงรูปของรางวัล
        if (selectedReward) {
            rewardImage.src = `${imgPath}${selectedReward.itemName}.png`;
            rewardImage.style.display = "block";
            rewardImage.style.opacity = 1; // ให้โชว์ชัดเจนตั้งแต่แรก
        }
    }

    function startScratch(e) {
        isDrawing = true;
        [lastX, lastY] = [e.offsetX, e.offsetY];
    }

    function scratch(e) {
        if (!isDrawing) return;
        
        // เล่นเสียงขูด
        if (scratchSound.paused) {
            scratchSound.currentTime = 0;
            scratchSound.play();
        }
    
        ctx.beginPath();
        ctx.moveTo(lastX, lastY);
        ctx.lineTo(e.offsetX, e.offsetY);
        ctx.lineWidth = 30;
        ctx.lineCap = "round";
        ctx.stroke();
        [lastX, lastY] = [e.offsetX, e.offsetY];
    
        checkScratchProgress();
    }

    function endScratch() {
        isDrawing = false;
    }

    function checkScratchProgress() {
        // ปรับการคำนวณความคืบหน้าให้มีหน่วงเวลาเล็กน้อยเพื่อประสิทธิภาพ
        let imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        let totalPixels = imageData.data.length / 4;
        let transparentPixels = 0;

        for (let i = 3; i < imageData.data.length; i += 4) {
            if (imageData.data[i] === 0) {
                transparentPixels++;
            }
        }

        // คำนวณความคืบหน้า
        let newProgress = (transparentPixels / totalPixels) * 100;

        if (Math.abs(newProgress - scratchProgress) > 5) { // อัปเดตเฉพาะเมื่อความคืบหน้ามีการเปลี่ยนแปลงเกิน 5%
            scratchProgress = newProgress;
        }
        // console.log(`${scratchProgress.toFixed(2)}%`);
        if (scratchProgress >= 30 && !rewardGiven) {
            rewardGiven = true;
            sendReward();
        }
    }

    function sendReward() {
        if (selectedReward && rewardGiven) {
            $.post(`https://${GetParentResourceName()}/claimReward`, JSON.stringify({
                reward: selectedReward
            }));
        }
    }

    canvas.addEventListener("mousedown", startScratch);
    canvas.addEventListener("mousemove", scratch);
    canvas.addEventListener("mouseup", endScratch);
    canvas.addEventListener("mouseleave", endScratch);

    canvas.addEventListener("touchstart", (e) => {
        e.preventDefault();
        startScratch(e.touches[0]);
    });
    canvas.addEventListener("touchmove", (e) => {
        e.preventDefault();
        scratch(e.touches[0]);
    });
    canvas.addEventListener("touchend", endScratch);

    window.addEventListener("message", function (event) {
        if (event.data.type === "SHOW_REWARD") {
            let rewardData = event.data.reward;
            imgPath = event.data.imgPath;
            // แสดงผลรูปของรางวัล
            rewardImage.src = `${imgPath}${rewardData.itemName}.png`;
            rewardImage.style.display = "block";

            // อัปเดต selectedReward ให้ตรงกับค่าจาก Server
            selectedReward = rewardData;
            showScratchUI()
            resizeCanvas(); // ปรับขนาด canvas และแสดงรางวัล
        }
    });

    document.addEventListener("keydown", function (event) {
        if (event.key === "Escape") { // ถ้ากดปุ่ม ESC
            // เล่นเสียงตอนรับรางวัล
            rewardSound.play();
            closeUI(); // เรียกฟังก์ชันเพื่อปิด UI
        }
    });

    function closeUI() {
        const container = document.querySelector('.scratch-container');
        container.style.opacity = 0; // ซ่อน container
        rewardImage.style.display = "none";  // ซ่อนรูปของรางวัล
        selectedReward = null;  // รีเซ็ตค่า selectedReward
        scratchProgress = 0;  // รีเซ็ตค่า progress
        rewardGiven = false;  // รีเซ็ตสถานะการได้รับรางวัล
        $.post(`https://${GetParentResourceName()}/closeUI`, JSON.stringify({}));
    }
    
    // แสดง .scratch-container เมื่อผู้เล่นเริ่มใช้งาน
    function showScratchUI() {
        const container = document.querySelector('.scratch-container');
        container.style.opacity = 1; // ทำให้ container ปรากฏ
    }

});
