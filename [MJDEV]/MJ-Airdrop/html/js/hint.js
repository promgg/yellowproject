/* =========================================================
   MJ-Airdrop | html/js/hint.js
   - Bottom-center loot hint (NUI)
   - Controlled from Lua via SendNUIMessage
     { action:"LootHint", show:true/false, title, sub, key, state }
   ========================================================= */

(() => {
  "use strict";

  const root = document.getElementById("lootHint");
  const keyEl = document.getElementById("lootHintKey");
  const titleEl = document.getElementById("lootHintTitle");
  const subEl = document.getElementById("lootHintSub");

  const STATES = ["is-ready", "is-busy", "is-error", "is-locked"];

  function setState(state) {
    if (!root) return;
    for (const s of STATES) root.classList.remove(s);
    if (state) root.classList.add(String(state));
  }

  function show(title, sub, key, state) {
    if (!root) return;
    root.classList.remove("is-hidden");

    if (titleEl && title !== undefined) titleEl.textContent = String(title ?? "");
    if (subEl && sub !== undefined) subEl.textContent = String(sub ?? "");

    if (keyEl) {
      const k = String(key ?? "").trim();
      if (k.length > 0) {
        keyEl.textContent = k;
        keyEl.style.display = "flex";
      } else {
        keyEl.style.display = "none";
      }
    }

    setState(state);
  }

  function hide() {
    if (!root) return;
    root.classList.add("is-hidden");
    setState(null);
  }

  window.addEventListener("message", (event) => {
    const data = event.data || {};
    const action = String(data.action || "");
    if (action !== "LootHint") return;

    if (data.show) {
      show(
        data.title ?? "กดค้าง G เพื่อเก็บ Airdrop",
        data.sub ?? "ปล่อยปุ่ม/โดนดาเมจ = ยกเลิก",
        data.key ?? "G",
        data.state ?? "is-ready"
      );
    } else {
      hide();
    }
  });

  hide();
})();
