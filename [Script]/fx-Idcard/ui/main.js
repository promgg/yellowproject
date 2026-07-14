(() => {
    const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "fx-Idcard";
    const fallbackPhoto = "/ui/assets/printphoto.png";
    const state = { token: "", steamAvatar: "", mode: "", price: 0, busy: false };

    const serviceMenu = document.getElementById("service-menu");
    const cardForm = document.getElementById("card-form");
    const idCard = document.getElementById("id-card");
    const imageUrl = document.getElementById("image-url");
    const formPhoto = document.getElementById("form-photo");

    function post(eventName, payload = {}) {
        return fetch(`https://${resourceName}/${eventName}`, {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify(payload),
        });
    }

    function setText(id, value) {
        const element = document.getElementById(id);
        if (element) element.textContent = value ?? "-";
    }

    function setPhoto(element, value) {
        if (!element) return;
        element.onerror = () => {
            element.onerror = null;
            element.src = fallbackPhoto;
        };
        element.src = value && String(value).trim() ? value : fallbackPhoto;
    }

    function hideAll() {
        serviceMenu.classList.add("hidden");
        cardForm.classList.add("hidden");
        idCard.classList.add("hidden");
        document.body.classList.remove("has-panel");
        state.busy = false;
        document.querySelectorAll("button").forEach((button) => { button.disabled = false; });
    }

    function showPanel(panel) {
        hideAll();
        panel.classList.remove("hidden");
        if (panel !== idCard) document.body.classList.add("has-panel");
    }

    function setBusy(value) {
        state.busy = value;
        document.querySelectorAll("button").forEach((button) => {
            if (!button.matches("[data-close]")) button.disabled = value;
        });
    }

    function setupServiceMenu(payload) {
        const card = payload.card || {};
        state.token = payload.token || "";
        state.mode = "menu";

        setPhoto(document.getElementById("menu-photo"), card.img);
        setText("menu-name", card.name);
        setText("menu-charid", `หมายเลขประจำตัว: ${card.charid || "-"}`);
        setText("menu-city", `สถานที่ออกบัตร: ${card.cityname || "-"}`);
        setText("change-photo-price", `ค่าธรรมเนียม $${payload.prices?.changePhoto ?? 25}`);
        setText("replacement-price", `ค่าธรรมเนียม $${payload.prices?.replacement ?? 50}`);
        // ออกบัตรทดแทนมีไว้เฉพาะตอนบัตรเดิมหายจริง — ถ้ายังมีอยู่ในกระเป๋าก็ซ่อนปุ่มนี้ไปเลย ไม่ต้องให้กดแล้วโดนปฏิเสธ
        document.getElementById("replacement").classList.toggle("hidden", !!payload.hasPhysicalCard);
        showPanel(serviceMenu);
    }

    function setupCardForm(payload) {
        const card = payload.card || {};
        state.token = payload.token || "";
        state.mode = payload.mode || "create";
        state.price = Number(payload.price) || 0;
        state.steamAvatar = payload.steamAvatar || "";

        setText("form-title", state.mode === "change_photo" ? "เปลี่ยนรูปประจำตัว" : "ทำบัตรประจำตัว");
        setText(
            "form-subtitle",
            state.mode === "change_photo"
                ? "URL ใหม่จะอัปเดตบัตรทุกสำเนาที่อ้างอิงทะเบียนนี้"
                : "ตรวจสอบข้อมูลและยืนยัน URL รูปประจำตัว"
        );
        setText("form-name", card.name);
        setText("form-charid", card.charid);
        setText("form-city", card.cityname);
        setText("form-sex", card.sex === "Female" ? "หญิง" : "ชาย");
        setText("form-age", card.age);
        setText("form-birthdate", card.date);
        setText("form-height", card.height);
        setText("form-weight", card.weight);
        setText("submit-card", `ยืนยันและชำระ $${state.price}`);

        imageUrl.value = card.img || state.steamAvatar || "";
        setPhoto(formPhoto, imageUrl.value);
        showPanel(cardForm);
        document.getElementById("use-steam-avatar").disabled = !state.steamAvatar;
    }

    function setupIdCard(card) {
        const sex = card.sex === "Female" ? "F" : "M";
        setPhoto(idCard.querySelector(".playerimg"), card.img);
        idCard.querySelector(".charid").textContent = card.charid || "N/A";
        idCard.querySelector(".sex").textContent = sex;
        idCard.querySelector(".height").textContent = card.height || "N/A";
        idCard.querySelector(".weight").textContent = card.weight || "N/A";
        idCard.querySelector(".dateofbirth").textContent = card.date || "N/A";
        idCard.querySelector(".age").textContent = card.age ?? "N/A";
        idCard.querySelector(".license").textContent = `${card.numberPrefix || "FIXITFY-"}${card.charid || "N/A"}`;
        idCard.querySelector(".name").textContent = card.name || "N/A";
        idCard.querySelector(".country").textContent = card.country || "U.S.A";
        idCard.querySelector(".card-zone").textContent = card.cityname || "N/A";
        showPanel(idCard);
    }

    document.querySelectorAll("[data-close]").forEach((button) => {
        button.addEventListener("click", () => {
            hideAll();
            post("close");
        });
    });

    document.getElementById("change-photo").addEventListener("click", () => {
        if (state.busy) return;
        setBusy(true);
        post("selectService", { token: state.token, service: "change_photo" }).finally(() => setBusy(false));
    });

    document.getElementById("replacement").addEventListener("click", () => {
        if (state.busy) return;
        setBusy(true);
        post("selectService", { token: state.token, service: "replacement" }).finally(() => {
            window.setTimeout(() => setBusy(false), 500);
        });
    });

    imageUrl.addEventListener("input", () => setPhoto(formPhoto, imageUrl.value));

    document.getElementById("use-steam-avatar").addEventListener("click", () => {
        if (!state.steamAvatar) return;
        imageUrl.value = state.steamAvatar;
        setPhoto(formPhoto, state.steamAvatar);
    });

    document.getElementById("submit-card").addEventListener("click", () => {
        if (state.busy) return;
        setBusy(true);
        post("submitCard", { token: state.token, imageUrl: imageUrl.value }).finally(() => {
            window.setTimeout(() => setBusy(false), 500);
        });
    });

    document.addEventListener("keyup", (event) => {
        if (event.key !== "Escape") return;
        hideAll();
        post("close");
    });

    window.addEventListener("message", (event) => {
        const message = event.data || {};
        switch (message.action) {
            case "openServiceMenu":
                setupServiceMenu(message.payload || {});
                break;
            case "openCardForm":
                setupCardForm(message.payload || {});
                break;
            case "previewCard":
                setupIdCard(message.payload || {});
                break;
            case "closeAll":
                hideAll();
                break;
        }
    });
})();
