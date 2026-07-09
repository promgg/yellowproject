-- ทดสอบ MJ-Progressbar ด้วย command /testpb [duration] [label]
-- ตัวอย่าง: /testpb 5000 Mining...
-- ตัวอย่าง: /testpb 10000 Harvesting... (BACKSPACE เพื่อยกเลิก)

RegisterCommand('testpb', function(source, args)
    local duration = tonumber(args[1]) or 5000
    local label    = args[2] and table.concat(args, ' ', 2) or 'Testing...'

    if isDoingAction then
        TriggerEvent('vorp:TipBottom', 'Progress bar is already running.', 2000)
        return
    end

    print(('[testpb] start — duration=%d label=%s'):format(duration, label))

    exports['MJ-Progressbar']:Progress({
        name        = 'test_action',
        duration    = duration,
        label       = label,
        icon        = 'bandage',          -- ไอเทม vorp_inventory ที่มีอยู่แน่ๆ
        useWhileDead = false,
        canCancel   = true,
        controlDisables = {
            disableMovement    = false,
            disableCarMovement = false,
            disableMouse       = false,
            disableCombat      = false,
        },
        animation = {
            task = 'WORLD_HUMAN_GUARD_STAND',
        },
    }, function(cancelled)
        if cancelled then
            print('[testpb] CANCELLED by player')
            TriggerEvent('vorp:TipBottom', 'Cancelled!', 2000)
        else
            print('[testpb] FINISHED successfully')
            TriggerEvent('vorp:TipBottom', 'Done! (' .. duration .. 'ms)', 2000)
        end
    end)
end, false)

-- /cancelpb — บังคับยกเลิกจากภายนอก (ทดสอบ cancel event)
RegisterCommand('cancelpb', function()
    TriggerEvent('progressbar:client:cancel')
end, false)
