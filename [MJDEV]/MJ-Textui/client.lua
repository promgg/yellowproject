function SendNUIMessageTextUI(msg)
    if not IsPauseMenuActive() then
        if msg then
            msg = msg:gsub("~r~", "<span style=color:red;>")
            msg = msg:gsub("~b~", "<span style='color:rgb(0, 213, 255);'>")
            msg = msg:gsub("~g~", "<span style='color:rgb(0, 255, 68);'>")
            msg = msg:gsub("~y~", "<span style=color:yellow;>")
            msg = msg:gsub("~p~", "<span style='color:rgb(220, 0, 255);'>")
            msg = msg:gsub("~f~", "<span style=color:grey;>")
            msg = msg:gsub("~m~", "<span style=color:darkgrey;>")
            msg = msg:gsub("~u~", "<span style=color:black;>")
            msg = msg:gsub("~o~", "<span style=color:gold;>")
            msg = msg:gsub("~s~", "</span>")
            msg = msg:gsub("~w~", "</span>")
            msg = msg:gsub("~b~", "<b>")
            msg = msg:gsub("~n~", "<br>")
            msg = msg:gsub("\n", "<br>")
            msg = msg:gsub("~input~", "<span class = 'INPUT_CONTEXT'>")
            msg = msg:gsub("~INPUT_CONTEXT~", "<span class = 'INPUT_CONTEXT'>E</span>")
            msg = msg:gsub("~INPUT_DETONATE~", "<span class = 'INPUT_CONTEXT'>G</span>")
            msg = msg:gsub("~INPUT_VEH_EXIT~", "<span class = 'INPUT_CONTEXT'>F</span>")
            msg = msg:gsub("~INPUT_ARREST~", "<span class = 'INPUT_CONTEXT'>F</span>")
            msg = msg:gsub("~INPUT_RELOAD~", "<span class = 'INPUT_CONTEXT'>R</span>")
            msg = msg:gsub("~INPUT_CONTEXT_SECONDARY~", "<span class = 'INPUT_CONTEXT'>Q</span>")
            msg = msg:gsub("~INPUT_COVER~", "<span class = 'INPUT_CONTEXT'>Q</span>")
            msg = msg:gsub("~INPUT_DIVE~", "<span class = 'INPUT_CONTEXT'>SPACEBAR</span>")
            msg = msg:gsub("~INPUT_VEH_HANDBRAKE~", "<span class = 'INPUT_CONTEXT'>SPACEBAR</span>")
            msg = msg:gsub("~INPUT_VEH_DUCK~", "<span class = 'INPUT_CONTEXT'>X</span>")
            msg = "<span style=color:currentColor>" .. msg .. "</span>"
    
            SendNUIMessage({ 
                action = 'showHelp',
                message = msg;
            })
        end
    end
end

function HideNUIMessageTextUI()
    SendNUIMessage({
        action = 'hideHelp'
    })
end

exports("ShowTextUI", SendNUIMessageTextUI)
exports("HideTextUI", HideNUIMessageTextUI)


--exports["MJ-Textui"]:ShowTextUI("Press ~INPUT_CONTEXT~ OpenATM")

-- local inZone = false
-- local enteredZone = false

-- if inZone and not enteredZone then
--     exports['MJ-Textui']:ShowTextUI("กด <span class = 'INPUT_CONTEXT'>E</span> เพื่อลงสู่พื้น")
--     enteredZone = true  -- ตั้งค่าหลังแสดงข้อความแล้ว
-- elseif not inZone and enteredZone then
--     exports['MJ-Textui']:HideTextUI()
--     enteredZone = false  -- รีเซ็ตเพื่อแสดงข้อความใหม่เมื่อเข้าเขตอีกครั้ง
-- end