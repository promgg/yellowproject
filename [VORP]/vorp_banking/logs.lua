Config                        = Config or {}
-- webhook urls for discord logging — อ่านจาก convar แทน hardcode ในไฟล์นี้ (git-tracked) เพื่อไม่ให้
-- webhook URL หลุดขึ้น repo ตั้งค่าจริงผ่าน `set` ใน server.cfg (ไม่ถูก version-control) เช่น:
--   set vorp_banking_withdraw_webhook "https://discord.com/api/webhooks/..."
-- ใช้ webhook เดียวกันได้ทุกช่องถ้าต้องการ log รวมช่องเดียว server-side only (logs.lua เป็น
-- server_scripts ใน fxmanifest) จึงไม่มีทางที่ client จะอ่าน URL นี้ได้

Config.WithdrawLogWebhook     = GetConvar('vorp_banking_withdraw_webhook', '')

Config.DepositLogWebhook      = GetConvar('vorp_banking_deposit_webhook', '')

Config.TransferLogWebhook     = GetConvar('vorp_banking_transfer_webhook', '')

Config.TakeLogWebhook         = GetConvar('vorp_banking_take_webhook', '')

Config.MoveLogWebhook         = GetConvar('vorp_banking_move_webhook', '')

Config.CustomInventoryWebhook = GetConvar('vorp_banking_custominv_webhook', '') -- will log anything for the custom inventory storage
