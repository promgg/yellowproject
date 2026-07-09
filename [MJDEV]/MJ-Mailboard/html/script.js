let allPosts = [];
let myIdentifier = null; // เก็บค่า identifier ของเราเอง
let lastPostTime = 0;

// รับข้อมูลจาก server
window.addEventListener("message", function (event) {
    const data = event.data;
    if (data.action === 'showUI') {
        $(".board-container").show();
        myIdentifier = data.identifier;
        allPosts = data.posts;
        renderPosts("all");
    }
    if (data.action === "loadMails") {
        allPosts = data.mails;
        myIdentifier = data.myIdentifier; // << ตัวแปรนี้ใช้เทียบโพสต์เรา
        renderPosts("all");
    }
});

// ฟังก์ชันแสดงโพสต์ตาม filter
function renderPosts(filter) {
    $("#post-list").empty();
    let filtered = Array.isArray(allPosts) ? allPosts : [];

    if (filter === "mine") {
        if (!myIdentifier) {
            $("#post-list").append(`<p>ไม่พบข้อมูลผู้ใช้</p>`);
            return;
        }
        filtered = filtered.filter(post => post.identifier === myIdentifier);
    }

    if (!Array.isArray(filtered) || filtered.length === 0) {
        $("#post-list").append(`<p style="text-align:center;">ไม่มีประกาศ</p>`);
        return;
    }

    filtered.forEach(post => {
        const date = new Date(post.time * 1000); // แปลงจาก timestamp
        const formattedTime = date.toLocaleString("th-TH", {
            day: "2-digit", month: "2-digit", year: "numeric",
            hour: "2-digit", minute: "2-digit"
        });

        const postEl = $(`
            <div class="post" data-id="${post.id}">
                <span class="post-author">🧑 โดยคุณ: ${post.charname}</span>
                <p class="post-text">${escapeHtml(post.text)}</p>
                ${post.image ? `<img src="${post.image}" />` : ""}
                <small class="post-time">🕒 โพสต์เมื่อ: ${formattedTime}</small>
                ${post.identifier === myIdentifier
                    ? `<button class="btn delete-btn" onclick="deletePost(${post.id})">ลบ</button>`
                    : ""}
            </div>
        `);
        $("#post-list").append(postEl);
    });
}

// Escape ป้องกัน script injection
function escapeHtml(unsafe) {
    return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

$(document).ready(function () {
    $(".board-container").hide();

    $("#allBtn").click(function () {
        renderPosts("all");
    });

    $("#mineBtn").click(function () {
        renderPosts("mine");
    });

    $(document).on("keydown", function (e) {
        if (e.key === "Escape") {
            closeUI();
        }
    });
});


// Modal การโพสต์
function openPostModal() {
    $("#postModal").removeClass("hidden");
}

function closePostModal() {
    $("#postModal").addClass("hidden");
}

// ส่งโพสต์ใหม่ไป server

function submitPost() {
    const now = Date.now();
    if (now - lastPostTime < 10000) {
        alert("กรุณารอ 10 วินาที ก่อนโพสต์ใหม่");
        return;
    }

    const text = $("#postText").val().trim();
    const image = $("#imageUrl").val().trim();

    if (!text) return;

    $.post("https://MJ-Mailboard/createPost", JSON.stringify({
        message: text,
        imageURL: image
    }), function (response) {
        if (response.success) {
            lastPostTime = now;
            closePostModal();
            $.post("https://MJ-Mailboard/getPosts", JSON.stringify({}));
        }
    });
}


// ลบโพสต์
function deletePost(postId) {
    $.post("https://MJ-Mailboard/deletePost", JSON.stringify({ postId: postId }), function (response) {
        if (response.success) {
            allPosts = allPosts.filter(p => p.id !== postId);
            renderPosts("mine");
        }
    });
}

function closeUI() {
    $(".board-container").hide();
    $.post("https://MJ-Mailboard/closeUI", JSON.stringify({}));
}
