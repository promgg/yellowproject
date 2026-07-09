
RegisterNetEvent('vorpcharacter_outfit:Updatecomps')
AddEventHandler('vorpcharacter_outfit:Updatecomps', function(data, source)
   ExecuteCommand("rc")
   Wait(1500)
   ExecuteCommand("Boots")
   Wait(100)
   ExecuteCommand("Boots")
end)