window.addEventListener('message', function(event) {
    let data = event.data;
    let iconContainer = document.getElementById('playerIcon');

    if (data.display) {
        iconContainer.style.display = "flex"; // แสดงไอคอน
        iconContainer.style.background = data.color === "green" ? "green" : "red"; // เปลี่ยนสีพื้นหลัง
    } else {
        iconContainer.style.display = "none"; // ซ่อนไอคอน
    }
});
