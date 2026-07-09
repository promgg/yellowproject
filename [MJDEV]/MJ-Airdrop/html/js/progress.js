/* =========================================================
   MJ-Airdrop | html/js/progress.js (ALL)
   - Hold-to-loot progress overlay (lootProgress)
   - Shows players in zone (current/max)
   - Compatible with:
       action: "LootProgress"   (Lua sends: {show,label,duration,players,maxPlayers})
       action: "openProgress" / "updateProgress" / "closeProgress" (legacy)
   ========================================================= */

(() => {
  "use strict";

  const root = document.getElementById("lootProgress");
  const titleEl = document.getElementById("lootProgressTitle");
  const playersEl = document.getElementById("lootProgressPlayers");
  const fillEl = document.getElementById("lootProgressFill");
  const pctEl = document.getElementById("lootProgressPct");

  const clamp = (v, min, max) => Math.min(Math.max(v, min), max);

  let visible = false;
  let raf = null;
  let start = 0;
  let duration = 0;

  function setPlayers(players, maxPlayers) {
    if (!playersEl) return;
    const p = Number(players) || 0;
    const m = Number(maxPlayers) || 0;
    if (m > 0) playersEl.textContent = `ผู้เล่นในวง: ${p}/${m}`;
    else playersEl.textContent = `ผู้เล่นในวง: ${p}`;
  }

  function setPercent(pct) {
    const p = clamp(Number(pct) || 0, 0, 100);
    if (fillEl) fillEl.style.width = `${p}%`;
    if (pctEl) pctEl.textContent = `${Math.round(p)}%`;
  }

  function show(label) {
    if (!root) return;
    root.classList.remove("is-hidden");
    visible = true;
    if (titleEl && label !== undefined) titleEl.textContent = String(label);
  }

  function hide() {
    visible = false;
    if (raf) {
      cancelAnimationFrame(raf);
      raf = null;
    }
    if (!root) return;
    root.classList.add("is-hidden");
    setPercent(0);
  }

  function tick(now) {
    if (!visible) return;
    if (!duration || duration <= 0) {
      setPercent(0);
      raf = null;
      return;
    }

    const t = clamp((now - start) / duration, 0, 1);
    setPercent(t * 100);

    if (t < 1) {
      raf = requestAnimationFrame(tick);
    } else {
      raf = null;
    }
  }

  function startProgress(label, durationMs, players, maxPlayers) {
    show(label);
    setPlayers(players, maxPlayers);
    setPercent(0);

    start = performance.now();
    duration = Number(durationMs) || 0;

    if (raf) cancelAnimationFrame(raf);
    raf = requestAnimationFrame(tick);
  }

  // ---------------------------------------------------------
  // NUI messages
  // ---------------------------------------------------------
  window.addEventListener("message", (event) => {
    const data = event.data || {};
    const action = String(data.action || "");

    // New (Lua): { action:"LootProgress", show:true/false, label, duration(ms), players, maxPlayers }
    if (action === "LootProgress") {
      if (data.show) {
        startProgress(data.label || "กำลังเปิดแอร์ดรอป", data.duration, data.players, data.maxPlayers);
      } else {
        hide();
      }
      return;
    }

    // Legacy support
    if (action === "openProgress" || action === "showProgress") {
      show(data.title || data.label || "กำลังเปิดแอร์ดรอป");
      if (data.players !== undefined || data.playersMax !== undefined) {
        setPlayers(data.players, data.playersMax);
      }
      if (data.percent !== undefined) {
        setPercent(data.percent);
      } else if (data.duration !== undefined) {
        // If someone sends duration (ms) without percent, run a time-based animation
        startProgress(data.title || data.label || "กำลังเปิดแอร์ดรอป", data.duration, data.players, data.playersMax);
      }
      return;
    }

    if (action === "updateProgress") {
      // If visible, update percent/players
      if (!visible) show(data.title || data.label || "กำลังเปิดแอร์ดรอป");
      if (data.players !== undefined || data.playersMax !== undefined) {
        setPlayers(data.players, data.playersMax);
      }
      if (data.percent !== undefined) {
        setPercent(data.percent);
      }
      return;
    }

    if (action === "setPlayers") {
      setPlayers(data.players, data.playersMax);
      return;
    }

    if (action === "closeProgress" || action === "hideProgress") {
      hide();
      return;
    }

    if (action === "cancelProgress") {
      // brief feedback then hide
      show(data.title || "ยกเลิก");
      if (titleEl && data.reason) titleEl.textContent = String(data.reason);
      setPercent(0);
      setTimeout(() => hide(), 350);
      return;
    }
  });

  // default hidden
  hide();
})();
