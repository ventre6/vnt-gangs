local QBCore = exports['qb-core']:GetCoreObject()
local isLoggedIn = false
local PlayerGang = {}
local currentAction = "none"

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() and QBCore.Functions.GetPlayerData() ~= {} then
        isLoggedIn = true
        PlayerGang = QBCore.Functions.GetPlayerData().gang
        getGangData()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    PlayerGang = QBCore.Functions.GetPlayerData().gang
    getGangData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate')
AddEventHandler('QBCore:Client:OnGangUpdate', function(GangInfo)
    PlayerGang = GangInfo
    isLoggedIn = true
end)

RegisterNetEvent("gang:client:getGangData", function()
    getGangData()
end)

function getGangData()
    QBCore.Functions.TriggerCallback("gang:server:getGangs", function(gangsData)
        if gangsData ~= nil and #gangsData > 0 then
            for confGang, confData in pairs(Config.gangs) do
                for _, sqlData in pairs(gangsData) do
                    if confGang == sqlData.gang then
                        confData.tacir.hasTacir = sqlData.tacir or 0
                        confData.market.hasMarket = sqlData.market or 0
                    end
                end
            end
        end
    end)
end

RegisterNetEvent('openStashMenu')
AddEventHandler('openStashMenu', function()
    if PlayerGang.grade.level <= 1 then
        QBCore.Functions.Notify("Rütben yetmiyor", "error")
        return
    end
    local stashId = PlayerGang.name .. "stash"
    exports.ox_inventory:openInventory('stash', stashId)
end)

RegisterNetEvent('openShopMenu')
AddEventHandler('openShopMenu', function()
    local shopId = PlayerGang.name .. "shop"
    exports.ox_inventory:openInventory('shop', {type= shopId})
end)

RegisterNetEvent('gang:addMember')
AddEventHandler('gang:addMember', function()
    if not PlayerGang.isboss then
        QBCore.Functions.Notify("Rütben yetmiyor", "error")
        return
    end
    local input = exports['qb-input']:ShowInput({
        header = "Gang Member Ekle",
        submitText = "Gönder",
        inputs = {
            {
                text = "Oyuncu ID'si",
                name = "player_id",
                type = "number",
                isRequired = true
            }
        }
    })

    if input then
        local playerId = tonumber(input.player_id)
        if playerId then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local targetPed = GetPlayerPed(GetPlayerFromServerId(playerId))
            local targetPos = GetEntityCoords(targetPed)

            if #(pos - targetPos) < 5.0 then
                TriggerServerEvent('gang:addMemberServer', playerId, PlayerGang.name)
            else
                QBCore.Functions.Notify('Oyuncu çok uzakta!', 'error')
            end
        end
    end
end)

RegisterNetEvent('ManageGang', function()
    local Player = QBCore.Functions.GetPlayerData()
    local Pgang = Player.gang.name
    local optionTable = {}
    local optionTable2 = nil

    QBCore.Functions.TriggerCallback('GetPlayersInGang', function(playersInGang)
        optionTable2 = playersInGang

        for k, v in ipairs(Config.gangs[Pgang].grades) do
            optionTable[#optionTable+1] = {value = k, text = v.name}
        end

        local dialog = exports["qb-input"]:ShowInput({
            header = 'Oluşum Yöneticisi',
            submitText = 'Onayla',
            inputs = {
                {
                    text = 'Oyuncu Seç',
                    name = "pid", 
                    type = "select", 
                    options = optionTable2,
                },
                {
                    text = 'Oluşumu düzenle',
                    name = "action",
                    type = "radio", 
                    options = { 
                        { value = "changerank", text = 'Rütbesini düzenle' }, 
                        { value = "fire", text = 'Oluşumdan çıkart' },
                    },
                },
                {
                    text = 'Rütbe seç',
                    name = "grade", 
                    type = "select", 
                    options = optionTable,
                }
            },
        })

        if dialog ~= nil then
            if dialog.action == 'changerank' then 
                local selectedGrade = tonumber(dialog.grade)
                TriggerServerEvent('ChangeGangRank', dialog.pid, Pgang, selectedGrade)
            elseif dialog.action == 'fire' then 
                TriggerServerEvent('RemoveFromGang', dialog.pid)
            end 
        end
    end, Pgang)
end)

RegisterNetEvent('gang:openTacirMenu')
AddEventHandler('gang:openTacirMenu', function()
    local Player = QBCore.Functions.GetPlayerData()
    local gangName = Player.gang.name
    local itemsForSale = Config.gangs[gangName].tacir.inventory
    local options = {}

    for _, item in pairs(itemsForSale) do
        local itemLabel = QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].label or item.name
        table.insert(options, { value = item.name, text = itemLabel .. ' - ' .. item.price .. ' $' })
    end

    local dialog = exports["qb-input"]:ShowInput({
        header = 'Tacir Satış Menüsü',
        submitText = 'Sat',
        inputs = {
            {
                text = 'Satmak istediğiniz itemi seçin',
                name = "itemName",
                type = "select",
                options = options,
            },
            {
                text = 'Satmak istediğiniz miktarı girin',
                name = "amount",
                type = "number",
                isRequired = true,
            }
        },
    })

    if dialog ~= nil then
        TriggerServerEvent('gang:sellItems', dialog.itemName, tonumber(dialog.amount))
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if isLoggedIn and PlayerGang.name ~= "none" then
            local gang = PlayerGang.name
            local gangConfig = Config.gangs[gang]
            
            if gangConfig then
                local stashPos = gangConfig.stash.coords
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)

                if stashPos then
                    local stashdist = #(pos - stashPos)
                    if stashdist < 20.0 then
                        DrawMarker(2, stashPos.x, stashPos.y, stashPos.z - 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 200, 200, 222, false, false, false, true, false, false, false)
                        if stashdist < 1.5 then
                            if IsControlJustReleased(0, 38) then
                                local menuData = {
                                    {
                                        header = "Oluşum Menü",
                                        icon = 'fas fa-people-roof',
                                        isMenuHeader = true
                                    },
                                    {
                                        header = "Depoyu Aç",
                                        txt = "Stash'i aç",
                                        icon = 'fas fa-box',
                                        params = {
                                            event = "openStashMenu"
                                        }
                                    },
                                    {
                                        header = "Oluşum üyelerini düzenle",
                                        txt = "Oluşumu düzenle",
                                        icon = 'fas fa-list-check',
                                        params = {
                                            event = "ManageGang"
                                        }
                                    },
                                    {
                                        header = "Gang Member Ekle",
                                        txt = "Gang member ekle",
                                        icon = 'fas fa-plus',
                                        params = {
                                            event = "gang:addMember"
                                        }
                                    },
                                }

                                for gang, data in pairs(Config.gangs) do
                                    if gang == gang then
                                        if data.tacir.hasTacir == 1 then
                                            table.insert(menuData, {
                                                header = "Tacir",
                                                txt = "Satış yap",
                                                icon = 'fas fa-cannabis',
                                                params = {
                                                    event = "gang:openTacirMenu"
                                                }
                                            })
                                        end
                                
                                        if data.market.hasMarket == 1 then
                                            table.insert(menuData, {
                                                header = "Market",
                                                txt = "Market'i aç",
                                                icon = 'fas fa-cart-shopping',
                                                params = {
                                                    event = "openShopMenu"
                                                }
                                            })
                                        end
                                    end
                                end
                                                          

                                table.insert(menuData, {
                                    header = "Menüyü Kapat",
                                    txt = "Menüyü kapat",
                                    icon = 'fas fa-xmark',
                                    params = {
                                        event = ""
                                    }
                                })

                                exports['qb-menu']:openMenu(menuData)
                            end
                        elseif stashdist < 2.0 then
                            currentAction = "none"
                        end
                    else
                        Wait(1000)
                    end
                else
                    Wait(2500)
                end
            else
                Wait(2500)
            end
        else
            Wait(2500)
        end
    end
end)
