# RedM Resource Todo

> สแกนอัตโนมัติจาก `resources/` (179 resources ที่มี fxmanifest.lua) เมื่อเริ่มสร้างไฟล์นี้ ทุก resource เริ่มต้นที่สถานะ 🔴 ยังไม่เริ่ม ตามที่ตกลงกันไว้ — ไม่มีการเดาสถานะจากความสมบูรณ์ของโค้ด
>
> **วิธีอัปเดตสถานะ:** พิมพ์ `อัปเดต [resource_name] เป็นสถานะ [X]` ใน session กับ Claude Code แล้วจะย้าย checkbox ให้ตรงหมวด (ใช้งานได้เฉพาะตอนสั่งในแชทเท่านั้น ไม่มี automation รันเอง)
>
> **ข้อจำกัดของการสแกน dependency:** ตรวจแบบ static grep หา `exports(...)`, `RegisterNetEvent`, `TriggerEvent`, `exports.resource:method()` ฯลฯ ในไฟล์ .lua ทั้งหมด — จับ event/export name ที่สร้างจาก string ต่อกัน (dynamic string concat) ไม่ได้, และ resource name ที่ export ใช้ อาจไม่ตรงกับชื่อ folder เป๊ะ ๆ ถือเป็น best-effort ใช้เป็นจุดเริ่มต้นตรวจสอบ ไม่ใช่ผลที่แม่นยำ 100%

## 🔴 ยังไม่เริ่ม

- [ ] Allmenu - ([Script]/Allmenu) #status/not-started
- [ ] Ath_Emerald - Ath_haras - Complete map package for RedM #status/not-started
- [ ] baseevents - Adds basic events for developers to use in their scripts. Some third party resources may depend on this resource. #status/not-started
- [ ] basic-gamemode - A basic freeroam gametype that uses the default spawn logic from spawnmanager. #status/not-started
- [ ] bcc-job-alerts - ([BCC]/bcc-job-alerts) #status/not-started
- [ ] bcc-minigames - ([BCC]/bcc-minigames) #status/not-started
- [ ] bcc-nazar - ([BCC]/bcc-nazar) #status/not-started
- [ ] bcc-robbery - ([BCC]/bcc-robbery) #status/not-started
- [ ] bcc-stables - ([BCC]/bcc-stables) #status/not-started
- [ ] bcc-train - ([BCC]/bcc-train) #status/not-started
- [ ] bcc-userlog - An in-depth and immersive user logging system for tracking player activity #status/not-started
- [ ] bcc-utils - A powerful developer utility for Redm #status/not-started
- [ ] bcc-wagons - ([BCC]/bcc-wagons) #status/not-started
- [ ] bln_3d_waypoint - A sleek and performant waypoint indicator system that shows a dynamic 3D marker pointing to your destination. #status/not-started
- [ ] bln_belt_attachments - Realistically display your weapons and items on your character's belt when equipped from inventory but not in use! Works with lanterns, lassos, machetes, and more. #status/not-started
- [ ] bln_map_discoveries - RedM script for enabling map discoveries! #status/not-started
- [ ] chat-theme-gtao - A GTA Online-styled theme for the chat resource. #status/not-started
- [ ] Daliyquest - Daily Quest NUI #status/not-started
- [ ] example-loadscreen - Example loading screen. #status/not-started
- [ ] ez_radialmenu - [STANDALONE] A radial menu for RedM #status/not-started
- [ ] feather-menu - A RedM Standalone UI system #status/not-started
- [ ] fivem - A compatibility resource to load basic-gamemode. #status/not-started
- [ ] fivem-map-hipster - Example spawn points for FiveM with a "hipster" model. #status/not-started
- [ ] fivem-map-skater - Example spawn points for FiveM with a "skater" model. #status/not-started
- [ ] fx-Idcard - Fixitfy Advanced IDCard #status/not-started
- [ ] hardcap - Limits the number of players to the amount set by sv_maxclients in your server.cfg. #status/not-started
- [ ] hud_hidebars - Hides cash/gold/tokens/honor HUD widgets every frame #status/not-started
- [ ] lockpick - storage script locations or and as items #status/not-started
- [ ] lp_allmenu - ([LP]/lp_allmenu) #status/not-started
- [ ] lp_animalFarm - ([Script]/lp_animalFarm) #status/not-started
- [ ] lp_blocktakeout - ([Script]/lp_blocktakeout) #status/not-started
- [ ] lp_daliyquest - Daily Quest NUI #status/not-started
- [ ] lp_itemnotify - Item add/remove toast notifications for vorp_inventory (replaces MJ-Itemnotify) #status/not-started
- [ ] lp_marketplace - Player Marketplace — VORPCore + vorp_inventory #status/not-started
- [ ] lp_minigame - Skill-check minigames (spacebar timing zone, WASD sequence, fishing catch) — client-only, blocking export API #status/not-started
- [ ] lp_progbar - Concurrent progress bars — client-only utility (export/event API) #status/not-started
- [ ] lp_rewardpanel - Reward-chance drop panel (icons + % + highlight-on-reward) — client-only utility (export API) #status/not-started
- [ ] lp_test - Scratch resource for one-off native/technique experiments (not for production) #status/not-started
- [ ] lp_textui - Key-prompt text UI with arc progress ring — client-only utility (export/event API) #status/not-started
- [ ] mapmanager - A flexible handler for game type/map association. #status/not-started
- [ ] MJ-Admin - ([MJDEV]/MJ-Admin) #status/not-started
- [ ] MJ-Afk-Zone-ui - MJDev AFK RedM #status/not-started
- [ ] MJ-AfkFishing - ([MJDEV]/MJ-AfkFishing) #status/not-started
- [ ] MJ-Airdrop - MJDev : https://discord.gg/gHRNMDQKzb #status/not-started
- [ ] MJ-Alert-Doctor - ([MJDEV]/MJ-Alert-Doctor) #status/not-started
- [ ] MJ-Alert-Police - ([MJDEV]/MJ-Alert-Police) #status/not-started
- [ ] MJ-Animal - MJ : Dev #status/not-started
- [ ] MJ-Announcement - ([MJDEV]/MJ-Announcement) #status/not-started
- [ ] MJ-Backpack - MJ-Backpack #status/not-started
- [ ] MJ-Beekeeper - Custom objects: Bee MJDEV #status/not-started
- [ ] MJ-CodeReward - MJ : Dev #status/not-started
- [ ] MJ-Color-Map - colored map taken from rdx core #status/not-started
- [ ] MJ-CompassUI - MJ CompassUI System for VORP #status/not-started
- [ ] MJ-ControlNPC - ([MJDEV]/MJ-ControlNPC) #status/not-started
- [ ] MJ-Cooldown - MJ-Cooldown #status/not-started
- [ ] MJ-Crafting - ([MJDEV]/MJ-Crafting) #status/not-started
- [ ] MJ-Deletehorse - JKL Delete Car #status/not-started
- [ ] MJ-Dimension - MJ Dimension Bucket System #status/not-started
- [ ] MJ-Duty - MJDevDuty #status/not-started
- [ ] MJ-Economy - ([MJDEV]/MJ-Economy) #status/not-started
- [ ] MJ-GetCoords - ([MJDEV]/MJ-GetCoords) #status/not-started
- [ ] MJ-GiftBox - GiftBox System for REDM #status/not-started
- [ ] MJ-Itemnotify - Item notification shim for vorp_inventory #status/not-started
- [ ] MJ-LoadingScreen - MJ SHOP #status/not-started
- [ ] MJ-Logo - a server logo resource #status/not-started
- [ ] MJ-LootPlayer - MJ-LootPlayer | updated by cl3i550n #status/not-started
- [ ] MJ-Lumberjack - Lumberjack — UI via lp_progbar/lp_textui/pNotify/lp_rewardpanel #status/not-started
- [ ] MJ-Mailboard - MJDev-Job for RedM #status/not-started
- [ ] MJ-Mailbox - MJ : Dev #status/not-started
- [ ] MJ-Medic - A medical scrpt for vorp core framework #status/not-started
- [ ] MJ-Mining - Mining — UI via lp_progbar/lp_textui/pNotify/lp_rewardpanel #status/not-started
- [ ] MJ-Notify - A robust RedM notify system using svelte #status/not-started
- [ ] MJ-Outfit - An outfit item based system #status/not-started
- [ ] MJ-Planting - ([MJDEV]/MJ-Planting) #status/not-started
- [ ] MJ-PlayerThreshold - ([MJDEV]/MJ-PlayerThreshold) #status/not-started
- [ ] MJ-Police - ([MJDEV]/MJ-Police) #status/not-started
- [ ] MJ-Process - MJ SHOP #status/not-started
- [ ] MJ-Progressbar - MJ-Progressbar #status/not-started
- [ ] MJ-RandomNumber - MJ : Dev #status/not-started
- [ ] MJ-Respwan - ([MJDEV]/MJ-Respwan) #status/not-started
- [ ] MJ-ScratchCard - MJ SHOP V1 #status/not-started
- [ ] MJ-Showitem - ([MJDEV]/MJ-Showitem) #status/not-started
- [ ] MJ-STATUS - ([MJDEV]/MJ-STATUS) #status/not-started
- [ ] MJ-StatusHud - MJDev Statushud #status/not-started
- [ ] MJ-Text3D - ([MJDEV]/MJ-Text3D) #status/not-started
- [ ] MJ-Textui - ([MJDEV]/MJ-Textui) #status/not-started
- [ ] MJ-TreasureMaps - ([MJDEV]/MJ-TreasureMaps) #status/not-started
- [ ] MJ-Voiceui - MJ SHOP #status/not-started
- [ ] MJ-WeaponDamage - ([MJDEV]/MJ-WeaponDamage) #status/not-started
- [ ] MJ-WelfareLogin - MJ Welfare Login Reward #status/not-started
- [ ] MJ-Ymaps - MJDev-Ymaps #status/not-started
- [ ] money - An example money system using KVS. #status/not-started
- [ ] money-fountain - An example money system client containing a money fountain. #status/not-started
- [ ] money-fountain-example-map - An example money system fountain spawn point. #status/not-started
- [ ] moonshine_interiors - ([standalone]/moonshine_interiors) #status/not-started
- [ ] mythic_progbar - ([Script]/mythic_progbar) #status/not-started
- [ ] npcdialogue_redm - NP Inspired Dialogue by Nexus | https://discord.gg/j87NTfVGQX #status/not-started
- [ ] nx_cityselect - City Selection System — VORP RedM #status/not-started
- [ ] nx_crafting - ([nx]/nx_crafting) #status/not-started
- [ ] nx_event - Auto Timed Treasure Hunt Event System #status/not-started
- [ ] nx_hud - Passive RedM NUI HUD with mounted horse status panel #status/not-started
- [ ] nx_minimap - Config-driven native minimap/radar position adjustment #status/not-started
- [ ] nx_shop - Fast server-authoritative VORP shop with NUI cart #status/not-started
- [ ] nx_util - Standalone RedM utility resource for shared server/client safeguards #status/not-started
- [ ] ox_lib - A library of shared functions to utilise in other resources. #status/not-started
- [ ] oxmysql - FXServer to MySQL communication via node-mysql2 #status/not-started
- [ ] ped-money-drops - An example money system client. #status/not-started
- [ ] player-data - A basic resource for storing player identifiers. #status/not-started
- [ ] playernames - A basic resource for displaying player names. #status/not-started
- [ ] pma-voice - VOIP built using FiveM's built in mumble. #status/not-started
- [ ] pNotify - ([Script]/pNotify) #status/not-started
- [ ] PolyZone - Define zones of different shapes and test whether a point is inside or outside of the zone #status/not-started
- [ ] poodlechat - Chat resource used on Poodle's Palace FiveM and RedM servers #status/not-started
- [ ] psg-gun-catalogue-vorp - ([Script]/psg-gun-catalogue-vorp) #status/not-started
- [ ] rconlog - Handles old-style server player management commands. #status/not-started
- [ ] redemrp_progressbars - ([Script]/redemrp_progressbars) #status/not-started
- [ ] redm-ipls - ([standalone]/redm-ipls) #status/not-started
- [ ] redm-map-one - Example spawn points for RedM. #status/not-started
- [ ] redm-ymaps - redm-ymaps #status/not-started
- [ ] rNotify - rnotify #status/not-started
- [ ] runcode - Allows server owners to execute arbitrary server-side or client-side JavaScript/Lua code. *Consider only using this on development servers. #status/not-started
- [ ] sessionmanager - Handles the "host lock" for non-OneSync servers. Do not disable. #status/not-started
- [ ] sessionmanager-rdr3 - Handles Social Club conductor session API for RedM. Do not disable. #status/not-started
- [ ] spawnmanager - Handles spawning a player in a unified fashion to prevent resources from having to implement custom spawn logic. #status/not-started
- [ ] spooni_ann_reborn - Annesburg Reborn #status/not-started
- [ ] spooni_bla_church - Blackwater Church #status/not-started
- [ ] spooni_rho_doctor - Rhodes Doctor #status/not-started
- [ ] spooni_spooner - Reworked Entity spawner for RedM #status/not-started
- [ ] spooni_val_street_stone - Valentine Street #status/not-started
- [ ] spooni_val_street_stone2 - Valentine Street #status/not-started
- [ ] spooni_val_street_wood - Valentine Street #status/not-started
- [ ] syn_minigame - ([standalone]/syn_minigame) #status/not-started
- [ ] uiprompt - ([standalone]/uiprompt) #status/not-started
- [ ] vorp_admin - VORP admin menu #status/not-started
- [ ] vorp_animations - A tool to define animations and use them in your scripts with an export #status/not-started
- [ ] vorp_banking - Bank system VORP #status/not-started
- [ ] vorp_barbershop - A barber shop for vorp core framework #status/not-started
- [ ] vorp_billing - Vorp billing system #status/not-started
- [ ] vorp_character - A Character creator with also shops built in for vorpcore framework #status/not-started
- [ ] vorp_cleangun - ([VORP]/vorp_cleangun) #status/not-started
- [ ] vorp_core - A Tool to build your RedM server and scripts #status/not-started
- [ ] vorp_crafting - A crafting script for vorpcore framework #status/not-started
- [ ] vorp_crawfish - A script to catch crawfish for vorp core framework #status/not-started
- [ ] vorp_doorlocks - Door System for RedM vorp core #status/not-started
- [ ] vorp_fishing - A fishing script for vorp core framework #status/not-started
- [ ] vorp_herbs - A Pick up Herbs script for vorp core framework #status/not-started
- [ ] vorp_horsepreview - Dev menu to preview every horse model and print its name/hash for debugging #status/not-started
- [ ] vorp_housing - A housing script for vorp #status/not-started
- [ ] vorp_hunting - A Hunting script for vorp core framework #status/not-started
- [ ] vorp_imapviewtool - ([VORP]/vorp_imapviewtool) #status/not-started
- [ ] vorp_inputs - An Input tool to use in your scripts for vorp core framework #status/not-started
- [ ] vorp_inventory - Inventory System for RedM VORPCore framework #status/not-started
- [ ] vorp_lib - A library to use for RedM scripts #status/not-started
- [ ] vorp_lootnpcs - A npc looting script for vorp core framework #status/not-started
- [ ] vorp_lumberjack - A lumberjack script for vorp core framework #status/not-started
- [ ] vorp_mailbox - A mailbox script for vorp core framework #status/not-started
- [ ] vorp_medic - A medical scrpt for vorp core framework #status/not-started
- [ ] vorp_menu - A tool to build RedM menus for your scripts #status/not-started
- [ ] vorp_metabolism - A Metabolism Script With HUD For VORP Core Framework #status/not-started
- [ ] vorp_mining - A mining script for vorp core framework #status/not-started
- [ ] vorp_outlaws - A Npc outlaw ambush scrip for vorp core framework #status/not-started
- [ ] vorp_paycheck - Paycheck System #status/not-started
- [ ] vorp_police - A police job for vorp core framework #status/not-started
- [ ] vorp_postman - ([VORP]/vorp_postman) #status/not-started
- [ ] vorp_progressbar - A tool to use within your scripts for vorp core framework #status/not-started
- [ ] vorp_sellhorse - Horse selling script for VORP Core #status/not-started
- [ ] vorp_stables - A Stables script for vorp core framework #status/not-started
- [ ] vorp_stores - A store script for vorp core framework #status/not-started
- [ ] vorp_utils - A library to help build your scripts for vorp core framework #status/not-started
- [ ] vorp_walkanim - A Menu to set walkstyles for vorp core framework #status/not-started
- [ ] vorp_weaponsv2 - A weapon handler with shops, crafting for vorp core framework #status/not-started
- [ ] vorp_wildhorse - Horse wild selling locations for vorp core framework #status/not-started
- [ ] vorp_zonenotify - A zone notify for vorp core framework #status/not-started
- [ ] weathersync - Time and weather synchronization for FiveM and RedM #status/not-started
- [ ] webpack - Builds resources with webpack. To learn more: https://webpack.js.org #status/not-started
- [ ] xakra_animations - xakra_animations #status/not-started
- [ ] xakra_flourishes - ([Script]/xakra_flourishes) #status/not-started
- [ ] xsound - ([standalone]/xsound) #status/not-started
- [ ] yarn - Builds resources with yarn. To learn more: https://classic.yarnpkg.com #status/not-started

## 🟡 กำลังเขียน

<!-- ว่างไว้ก่อน — ย้ายรายการมาที่นี่ด้วยคำสั่ง "อัปเดต [resource_name] เป็นสถานะ [X]" -->

## 🔵 เขียนเสร็จ รอเทส

<!-- ว่างไว้ก่อน — ย้ายรายการมาที่นี่ด้วยคำสั่ง "อัปเดต [resource_name] เป็นสถานะ [X]" -->

## 🟢 เทสผ่านแล้ว

<!-- ว่างไว้ก่อน — ย้ายรายการมาที่นี่ด้วยคำสั่ง "อัปเดต [resource_name] เป็นสถานะ [X]" -->

## ⚠️ จุดที่ยังไม่เชื่อมกัน (dependency ขาด)

- [ ] **Ath_Emerald** อ้างถึง `objectloader` (manifest dependency) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **fx-Idcard** อ้างถึง `rsg-core:GetCoreObject` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **MJ-Dimension** อ้างถึง `rsg-core:GetCoreObject` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **MJ-Police** อ้างถึง `ghmattimysql:execute` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **MJ-Police** อ้างถึง `ghmattimysql:executeSync` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **MJ-Police** อ้างถึง `syn_society:SetPlayerDuty` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **MJ-Respwan** อ้างถึง `screenshot-basic:requestScreenshotUpload` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **MJ-TreasureMaps** อ้างถึง `rsg-core:GetCoreObject` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **ox_lib** อ้างถึง `ox_target:addBoxZone` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **ox_lib** อ้างถึง `ox_target:addPolyZone` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **ox_lib** อ้างถึง `ox_target:addSphereZone` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **poodlechat** อ้างถึง `discord_rest` (manifest dependency) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **poodlechat** อ้างถึง `discord_rest:deleteMessage` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **poodlechat** อ้างถึง `discord_rest:executeWebhook` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **poodlechat** อ้างถึง `discord_rest:executeWebhookUrl` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **poodlechat** อ้างถึง `discord_rest:getChannel` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **poodlechat** อ้างถึง `discord_rest:getChannelMessages` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **poodlechat** อ้างถึง `discord_rest:getUser` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **rNotify** อ้างถึง `rsg-core` (manifest dependency) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **rNotify** อ้างถึง `rsg-core:GetCoreObject` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **vorp_barbershop** อ้างถึง `ghmattimysql:execute` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **vorp_crawfish** อ้างถึง `progressBars:startUI` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked
- [ ] **vorp_mailbox** อ้างถึง `ghmattimysql:execute` (export call) แต่หา resource ต้นทางไม่เจอในโปรเจกต์ #status/blocked

---

## Dependency Map

> resource ที่พบว่ามีการอ้างอิงไปยัง resource อื่น**ที่มีอยู่จริง**ในโปรเจกต์ (จาก `dependencies` ใน fxmanifest.lua และ `exports.<resource>:<method>()` ในโค้ด) — 94 resource, 221 เส้นเชื่อม

| Resource | พึ่งพา (Depends On) |
|---|---|
| `Allmenu` | `vorp_core` |
| `basic-gamemode` | `spawnmanager` |
| `bcc-job-alerts` | `vorp_core` |
| `bcc-nazar` | `bcc-userlog`, `vorp_core`, `vorp_inventory` |
| `bcc-robbery` | `bcc-job-alerts`, `vorp_core`, `vorp_inventory` |
| `bcc-stables` | `vorp_core`, `vorp_inventory` |
| `bcc-train` | `bcc-job-alerts`, `oxmysql`, `vorp_core`, `vorp_inventory`, `vorp_menu` |
| `bcc-userlog` | `vorp_core` |
| `bcc-utils` | `oxmysql` |
| `bcc-wagons` | `oxmysql`, `vorp_core`, `vorp_inventory` |
| `Daliyquest` | `oxmysql`, `vorp_core`, `vorp_inventory` |
| `ez_radialmenu` | `oxmysql`, `vorp_core` |
| `fivem` | `basic-gamemode` |
| `fx-Idcard` | `nx_hud`, `oxmysql`, `vorp_core`, `vorp_inventory` |
| `lp_allmenu` | `vorp_core` |
| `lp_animalFarm` | `lp_rewardpanel`, `lp_textui`, `pNotify`, `vorp_inventory` |
| `lp_daliyquest` | `oxmysql`, `vorp_core`, `vorp_inventory` |
| `lp_itemnotify` | `vorp_inventory` |
| `lp_marketplace` | `vorp_core`, `vorp_inventory` |
| `MJ-Admin` | `vorp_inventory` |
| `MJ-Afk-Zone-ui` | `lp_progbar`, `lp_textui`, `pNotify`, `vorp_core`, `vorp_inventory` |
| `MJ-AfkFishing` | `lp_minigame`, `lp_progbar`, `lp_rewardpanel`, `lp_textui`, `pNotify`, `vorp_core`, `vorp_inventory` |
| `MJ-Airdrop` | `MJ-Textui`, `pNotify`, `vorp_core`, `vorp_inventory` |
| `MJ-Animal` | `MJ-Textui`, `pNotify`, `vorp_core`, `vorp_inventory` |
| `MJ-Announcement` | `vorp_core` |
| `MJ-Backpack` | `vorp_core`, `vorp_inventory` |
| `MJ-Beekeeper` | `redemrp_progressbars`, `vorp_inventory` |
| `MJ-CodeReward` | `pNotify`, `vorp_core`, `vorp_inventory` |
| `MJ-Crafting` | `vorp_core`, `vorp_inventory` |
| `MJ-Deletehorse` | `vorp_core` |
| `MJ-Duty` | `vorp_inventory` |
| `MJ-Economy` | `lp_textui`, `vorp_core`, `vorp_inventory` |
| `MJ-GiftBox` | `vorp_core`, `vorp_inventory` |
| `MJ-LootPlayer` | `vorp_core`, `vorp_inventory` |
| `MJ-Lumberjack` | `lp_progbar`, `lp_rewardpanel`, `lp_textui`, `pNotify`, `vorp_core`, `vorp_inventory` |
| `MJ-Mailboard` | `MJ-Text3D`, `vorp_core` |
| `MJ-Mailbox` | `vorp_core`, `vorp_inventory` |
| `MJ-Medic` | `vorp_core`, `vorp_inputs`, `vorp_menu` |
| `MJ-Mining` | `lp_progbar`, `lp_rewardpanel`, `lp_textui`, `oxmysql`, `pNotify`, `vorp_core`, `vorp_inventory` |
| `MJ-Outfit` | `vorp_core`, `vorp_inventory` |
| `MJ-Planting` | `lp_progbar`, `lp_rewardpanel`, `lp_textui`, `pNotify`, `vorp_core`, `vorp_inventory` |
| `MJ-Police` | `syn_minigame`, `vorp_inventory` |
| `MJ-Progressbar` | `vorp_core` |
| `MJ-RandomNumber` | `vorp_core`, `vorp_inventory` |
| `MJ-Respwan` | `MJ-Progressbar`, `vorp_core`, `vorp_inventory` |
| `MJ-ScratchCard` | `vorp_inventory` |
| `MJ-STATUS` | `MJ-Showitem`, `vorp_core`, `vorp_inventory` |
| `MJ-StatusHud` | `MJ-STATUS` |
| `MJ-TreasureMaps` | `redemrp_progressbars`, `vorp_inventory` |
| `MJ-WelfareLogin` | `vorp_core`, `vorp_inventory` |
| `money-fountain` | `mapmanager`, `money` |
| `money-fountain-example-map` | `money-fountain` |
| `nx_cityselect` | `PolyZone`, `oxmysql`, `vorp_core` |
| `nx_crafting` | `lp_textui`, `vorp_core`, `vorp_inventory` |
| `nx_event` | `nx_cityselect`, `vorp_core` |
| `nx_shop` | `vorp_core`, `vorp_inventory` |
| `ped-money-drops` | `money` |
| `poodlechat` | `vorp_core` |
| `psg-gun-catalogue-vorp` | `vorp_core`, `vorp_inventory` |
| `sessionmanager-rdr3` | `yarn` |
| `spooni_spooner` | `uiprompt` |
| `vorp_admin` | `vorp_core`, `vorp_inventory`, `vorp_menu` |
| `vorp_banking` | `vorp_core`, `vorp_inventory`, `vorp_menu` |
| `vorp_barbershop` | `vorp_core` |
| `vorp_billing` | `vorp_core`, `vorp_inputs`, `vorp_inventory`, `vorp_menu` |
| `vorp_character` | `vorp_core`, `vorp_menu`, `weathersync` |
| `vorp_cleangun` | `vorp_core`, `vorp_inventory` |
| `vorp_core` | `spawnmanager`, `vorp_inventory`, `vorp_menu` |
| `vorp_crafting` | `vorp_core`, `vorp_inventory`, `vorp_progressbar` |
| `vorp_crawfish` | `vorp_core`, `vorp_inventory`, `vorp_progressbar` |
| `vorp_doorlocks` | `lockpick`, `vorp_core`, `vorp_inventory` |
| `vorp_fishing` | `vorp_core`, `vorp_inventory` |
| `vorp_herbs` | `vorp_core`, `vorp_inventory` |
| `vorp_horsepreview` | `vorp_menu` |
| `vorp_housing` | `vorp_character`, `vorp_core`, `vorp_doorlocks`, `vorp_inventory` |
| `vorp_hunting` | `vorp_core`, `vorp_inventory` |
| `vorp_imapviewtool` | `vorp_core` |
| `vorp_inventory` | `lp_itemnotify`, `vorp_core` |
| `vorp_lib` | `vorp_core` |
| `vorp_lootnpcs` | `vorp_core`, `vorp_inventory` |
| `vorp_lumberjack` | `syn_minigame`, `vorp_core`, `vorp_inventory` |
| `vorp_medic` | `vorp_core`, `vorp_inputs`, `vorp_menu` |
| `vorp_metabolism` | `vorp_core`, `vorp_inventory` |
| `vorp_mining` | `syn_minigame`, `vorp_core`, `vorp_inventory` |
| `vorp_paycheck` | `vorp_core` |
| `vorp_police` | `vorp_core`, `vorp_inputs`, `vorp_menu` |
| `vorp_sellhorse` | `vorp_core`, `vorp_inventory` |
| `vorp_stables` | `vorp_core`, `vorp_inventory` |
| `vorp_stores` | `vorp_core`, `vorp_inventory`, `vorp_menu` |
| `vorp_walkanim` | `oxmysql`, `vorp_core`, `vorp_menu` |
| `vorp_weaponsv2` | `vorp_core`, `vorp_progressbar` |
| `vorp_wildhorse` | `vorp_core` |
| `webpack` | `yarn` |
| `xakra_animations` | `oxmysql` |
