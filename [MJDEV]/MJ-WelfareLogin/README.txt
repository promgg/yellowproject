MJ-WelfareLogin UI Polish Pack

This pack contains a redesigned NUI for the welfare login system:
- Cleaner western-style layout
- Softer premium dark/gold palette
- Simpler card spacing and typography
- Animated loading overlay for refresh/open state

Files:
- html/index.html
- html/style.css
- html/app.js

Install:
1. Back up your current html folder.
2. Replace the files inside your existing resource html/ folder with the files in this pack.
3. If your current Lua sends different NUI message keys, map them to:
   - action = "open" / "close" / "state" / "refresh" / "loading"
   - open: boolean
   - loading: boolean
   - autoClaim: boolean
   - promptText: string
   - onlineText: string
   - nextReset: string
   - ui: { title, subtitle, accent, success, warning, danger }
   - tiers: [{ id, timeLabel, name, qty, state, image, description }]

Notes:
- This pack avoids external web fonts, so it works in NUI immediately.
- The font style is a western/classic serif look using local system fonts.
