local QBCore = exports['qb-core']:GetCoreObject()
local ox_inventory = exports.ox_inventory


CreateThread(function()
    for gang, data in pairs(Config.gangs) do
        local sqlData = MySQL.Async.fetchAll.await("SELECT `id` FROM vnt_gangs WHERE gang = ?", {gang})
        if sqlData == nil or #sqlData == 0 then
            MySQL.Async.execute("INSERT INTO vnt_gangs (gang, market, tacir) VALUES (?, ?, ?)", {gang, data.market.hasMarket, data.tacir.hasTacir})
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for gang, v in pairs(Config.gangs) do
            ox_inventory:RegisterStash(gang .. "stash", v.stash.name, 700, 4000000, gang)
            ox_inventory:RegisterShop(gang .. "shop", {
                name = v.market.name,
                inventory = v.market.inventory
            })
        end
    end
end)

RegisterNetEvent('gang:addMemberServer')
AddEventHandler('gang:addMemberServer', function(playerId, gangName)
    local src = source
    local targetPlayer = QBCore.Functions.GetPlayer(playerId)
    if targetPlayer then
        targetPlayer.Functions.SetGang(gangName)
        QBCore.Functions.Notify(src, 'Oyuncu gange eklendi!', 'success')
        QBCore.Functions.Notify(playerId, 'Gange katıldınız!', 'success')
    else
        QBCore.Functions.Notify(src, 'Oyuncu bulunamadı!', 'error')
    end
end)

QBCore.Functions.CreateCallback('GetPlayersInGang', function(source, cb, gang)
    local playersInGang = {}
    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        if player.PlayerData.gang.name == gang then
            table.insert(playersInGang, {
                value = player.PlayerData.source, 
                text = player.PlayerData.name,
                grade = player.PlayerData.gang.grade
            })
        end
    end
    cb(playersInGang)
end)

RegisterNetEvent('ChangeGangRank', function(pid, gang, grade)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(pid)

    if Player.PlayerData.gang.name == gang and Player.PlayerData.gang.isboss then
        Target.Functions.SetGang(gang, grade)
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, 'Rütben '..Config.gangs[gang].grades[grade].name.. ' olarak değiştirildi.', 'success')
        TriggerClientEvent('QBCore:Notify', src, 'İsimli oyuncunun '..Target.PlayerData.name..' rütbesini '..Config.gangs[gang].grades[grade].name.. ' değiştirdin.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Rütben yetmiyor.', 'error')
    end
end)

RegisterNetEvent('RemoveFromGang', function(pid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(pid)

    if Player.PlayerData.gang.name == Target.PlayerData.gang.name and Player.PlayerData.gang.isboss then
        Target.Functions.SetGang('none', 0)
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, 'Oluşumdan çıkarıldın.', 'error')
        TriggerClientEvent('QBCore:Notify', src, 'Oluşumdan '..Target.PlayerData.name..' isimli oyuncuyu çıkarttın.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Rütben yetmiyor.', 'error')
    end
end)

RegisterNetEvent('gang:sellItems')
AddEventHandler('gang:sellItems', function(itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local gangName = Player.PlayerData.gang.name
    local itemPrice = 0

    for _, item in pairs(Config.gangs[gangName].tacir.inventory) do
        if item.name == itemName then
            itemPrice = item.price
            break
        end
    end

    if itemPrice > 0 then
        local itemData = Player.Functions.GetItemByName(itemName)
        local itemCount = itemData and itemData.amount or 0
        local itemLabel = QBCore.Shared.Items[itemName] and QBCore.Shared.Items[itemName].label or itemName

        if itemCount >= amount then
            local totalAmount = itemPrice * amount
            Player.Functions.RemoveItem(itemName, amount)
            Player.Functions.AddMoney('cash', totalAmount, 'Tacir item satışı')
            TriggerClientEvent('QBCore:Notify', src, amount .. ' adet ' .. itemLabel .. ' sattın ve ' .. totalAmount .. ' $ kazandın.', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Yeterli miktarda ' .. itemLabel .. ' yok.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Bu item satılamaz.', 'error')
    end
end)

QBCore.Functions.CreateCallback("gang:server:getGangs", function(source, cb)
    local source = source
    MySQL.Async.fetchAll("SELECT * FROM vnt_gangs", {}, function(result)
        cb(result)
    end)
end)

QBCore.Commands.Add('settacir', "Bir gang için tacir ver", {{ name = 'gang', help = 'Gang adı' }, { name = 'tacir', help = 'Tacir vermek için 1 kapatmak için 0 (1 üstü otomatik olarak 1 olarak kabul edilir)' }}, false, function(source, args)
    local source = source
    if args[1] ~= nil then
        local gang = args[1]
        if args[2] ~= nil then
            local tacir = tonumber(args[2])
            if tacir ~= nil then
                if tacir > 1 then
                    tacir = 1
                elseif tacir < 0 then
                    tacir = 0
                end

                MySQL.Async.execute("UPDATE vnt_gangs SET tacir = ? WHERE gang = ?", {tacir, gang})
                TriggerClientEvent("gang:client:getGangData", -1)
                TriggerClientEvent('QBCore:Notify', source, 'İşlem yapıldı!', 'success')
            else
                TriggerClientEvent('QBCore:Notify', source, 'Tacir alanı verecekseniz 1 kapatacaksanız 0 girmeniz gerek!', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', source, 'Tacir alanı boş bırakılamaz!', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'Gang adı alanı boş bırakılamaz!', 'error')
    end
end, 'admin')

QBCore.Commands.Add('setmarket', "Bir gang için market ver", {{ name = 'gang', help = 'Gang adı' }, { name = 'market', help = 'Market vermek için 1 kapatmak için 0 (1 üstü otomatik olarak 1 olarak kabul edilir)' }}, false, function(source, args)
    local source = source
    if args[1] ~= nil then
        local gang = args[1]
        if args[2] ~= nil then
            local market = tonumber(args[2])
            if market ~= nil then
                if market > 1 then
                    market = 1
                elseif market < 0 then
                    market = 0
                end

                MySQL.Async.execute("UPDATE vnt_gangs SET market = ? WHERE gang = ?", {market, gang})
                TriggerClientEvent("gang:client:getGangData", -1)
                TriggerClientEvent('QBCore:Notify', source, 'İşlem yapıldı!', 'success')
            else
                TriggerClientEvent('QBCore:Notify', source, 'Market verecekseniz 1 kapatacaksanız 0 girmeniz gerek!', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', source, 'Market alanı boş bırakılamaz!', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'Gang adı alanı boş bırakılamaz!', 'error')
    end
end, 'admin')