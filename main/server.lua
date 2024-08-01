ESX = exports['es_extended']:getSharedObject()

if not Config.UseAdmin and Config.UseItem then
    ESX.RegisterUsableItem(Config.Item, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        local item = xPlayer.getInventoryItem(Config.Item).count
        if item > 0 and xPlayer.job.name == Config.UseJob then
            TriggerClientEvent("nvm_house:jobbuild", source)
        else
            xPlayer.showNotification("You can't use this..")
        end
    end)
end


local entered = {}

AddEventHandler('onResourceStart', function (resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    LoadData()
end)

LoadData = function()

    local file = json.decode(LoadResourceFile(GetCurrentResourceName(), "state.json")) or {}
    entered = file
end
SaveData = function()

    SaveResourceFile(GetCurrentResourceName(), 'state.json', json.encode(entered), -1)
end

ESX.RegisterServerCallback("nvm_house:setuphouse", function(source, cb, datas)
    local xPlayer = ESX.GetPlayerFromId(source)
    local bidentifier = xPlayer.identifier
    local bname = xPlayer.getName()
    if datas.isplayer then
        local xTarget = ESX.GetPlayerFromId(tonumber(datas.player))
        if xTarget then
            local oidentifier = xTarget.identifier
            local oname = xTarget.getName()
            local hcoords = json.encode({x=datas.house.x, y=datas.house.y, z=datas.house.z})
            local gcoords = json.encode({x=datas.garage.x, y=datas.garage.y, z=datas.garage.z, h=datas.garage.h})
            local interior = datas.interior
            MySQL.Async.execute('INSERT INTO nvm_houses (bidentifier, bname, oidentifier, oname, house_coords, garage_coords, interior, is_locked, is_buyable) VALUES (@bidentifier, @bname, @oidentifier, @oname, @housecoords, @garagecoords, @interior, @islocked, @isbuyable)', {
                ['@bidentifier'] = bidentifier,
                ['@bname'] = bname,
                ['@oidentifier'] = oidentifier,  
                ['@oname'] = oname, 
                ['@housecoords'] = hcoords, 
                ['@garagecoords'] = gcoords, 
                ['@interior'] = interior, 
                ['@islocked'] = true, 
                ['@isbuyable'] = false 
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    cb(true, true, "Sucesfully added to "..oidentifier.." player")
                end
            end)
        else
            cb(true, false, "Player is not online")
        end
    else        
        local hcoords = json.encode({x=datas.house.x, y=datas.house.y, z=datas.house.z})
        local gcoords = json.encode({x=datas.garage.x, y=datas.garage.y, z=datas.garage.z, h=datas.garage.h})
        local interior = datas.interior
        local price = datas.money
        MySQL.Async.execute('INSERT INTO nvm_houses (bidentifier, bname, house_coords, garage_coords, interior, is_locked, is_buyable, price) VALUES (@bidentifier, @bname, @housecoords, @garagecoords, @interior, @islocked, @isbuyable, @price)', {
            ['@bidentifier'] = bidentifier,
            ['@bname'] = bname,
            ['@housecoords'] = hcoords, 
            ['@garagecoords'] = gcoords, 
            ['@interior'] = interior, 
            ['@islocked'] = true, 
            ['@isbuyable'] = true,
            ['@price'] = price 
        }, function(rowsChanged)
            if rowsChanged > 0 then
                if Config.WebHook ~= "" then
                    sendToDiscord("BUILD","Builder Informations: \n\n**Identifier**: "..bidentifier.."\n**Name**: "..bname.."\n\n\n House Informations:\n\n**Coords**: ```"..datas.house.x.." "..datas.house.y.." "..datas.house.z.."```\n **Interior**: "..interior.."\n**Price**: "..price.."$ \n\n **Time** : "..os.date("%Y/%m/%d %X"))
                end
                cb(false, true, "Sucesfully builded for "..price.."$ price")
            end
        end)
    end
end)

ESX.RegisterServerCallback("nvm_house:getallhouse", function(source, cb)
    MySQL.Async.fetchAll('SELECT * FROM nvm_houses', {}, function(results)
        local houses = {}
        for i=1, #results, 1 do
            table.insert(houses, {
                id = results[i].id,
                bname = results[i].bname,
                oname = results[i].bname,
                hcoords = json.decode(results[i].house_coords),
                gcoords = json.decode(results[i].garage_coords),
                interior = results[i].interior,
                locked = results[i].is_locked,
                buyable = results[i].is_buyable,
                price = results[i].price
            })
        end
        cb(houses)
    end)
end)

ESX.RegisterServerCallback("nvm_house:getownerhouse", function(source, cb, identifier)
    MySQL.Async.fetchAll('SELECT * FROM nvm_houses WHERE oidentifier = @oidentifier OR id IN (SELECT house_id FROM nvm_houses_keys WHERE identifier = @oidentifier)', {
        ['@oidentifier'] = identifier
    }, function(results)
        local houses = {}
        for i=1, #results, 1 do
            table.insert(houses, {
                gcoords = json.decode(results[i].garage_coords)
            })
        end
        cb(houses)
    end)
end)

ESX.RegisterServerCallback("nvm_house:blips", function(source, cb, identifier)
    MySQL.Async.fetchAll('SELECT id, house_coords FROM nvm_houses WHERE oidentifier = @oidentifier OR id IN (SELECT house_id FROM nvm_houses_keys WHERE identifier = @oidentifier)', {
        ['@oidentifier'] = identifier
    }, function(results)
        local houses = {}
        for i=1, #results, 1 do
            table.insert(houses, {
                id = results[i].id,
                coords = json.decode(results[i].house_coords)
            })
        end
        cb(identifier, houses)
    end)
end)

ESX.RegisterServerCallback("nvm_house:lockstatus", function(source, cb, identifier, houseid)
    MySQL.Async.fetchAll('SELECT is_locked, oidentifier FROM nvm_houses WHERE id = @id', {
        ['@id'] = houseid
    }, function(house)
        if house[1] then
            local islocked = house[1].is_locked
            local owner = house[1].oidentifier == identifier

            MySQL.Async.fetchAll('SELECT house_id FROM nvm_houses_keys WHERE house_id = @id AND identifier = @identifier', {
                ['@id'] = houseid,
                ['@identifier'] = identifier
            }, function(keys)
                local cooowner = #keys > 0
                if islocked then
                    cb(true, owner or cooowner)
                else
                    cb(false, owner or cooowner)
                end
            end)
        else
            cb(false, false)
        end
    end)
end)

ESX.RegisterServerCallback("nvm_house:housetoggle", function(source, cb, identifier, houseid)
    MySQL.Async.fetchAll('SELECT is_locked FROM nvm_houses WHERE id = @id AND (oidentifier = @oidentifier OR id IN (SELECT house_id FROM nvm_houses_keys WHERE identifier = @oidentifier))', {
        ['@id'] = houseid,
        ['@oidentifier'] = identifier
        
    }, function(result)
        if result[1] then
            local currentState = result[1].is_locked
            if currentState then
                state = false
            else
                state = true
            end
            MySQL.Async.execute('UPDATE nvm_houses SET is_locked = @state WHERE id = @id AND (oidentifier = @oidentifier OR id IN (SELECT house_id FROM nvm_houses_keys WHERE identifier = @oidentifier))', {
                ['@state'] = state,
                ['@id'] = houseid,
                ['@oidentifier'] = identifier
            }, function(result)
                if result > 0 then
                    cb(state)
                end
            end)
        end
    end)
end)


ESX.RegisterServerCallback("nvm_house:buyhouse", function(source, cb, houseid, price, x , y ,z)
    local xPlayer = ESX.GetPlayerFromId(source)
    local oidentifier = xPlayer.identifier
    local oname = xPlayer.getName()
    local bankmoney = xPlayer.getAccount('bank').money
    if bankmoney >= price then
        xPlayer.removeAccountMoney('bank', price)
        MySQL.Async.execute('UPDATE nvm_houses SET oidentifier = @oidentifier, oname = @oname, is_buyable = @isbuyable WHERE id = @id', {
            ['@id'] = houseid,
            ['@oidentifier'] = oidentifier,
            ['@oname'] = oname,
            ['@isbuyable'] = false
        }, function(rowsChanged)
            if rowsChanged > 0 then
                if Config.WebHook ~= "" and Config.BuyHook then
                    sendToDiscord("House BUY","Buyer Informations: \n\n**Identifier**: "..oidentifier.."\n**Name**: "..oname.."\n\n\n House Informations:\n\n**Coords**: ```"..x.." "..y.." "..z.."```\n **House ID**: "..houseid.."\n**Price**: "..price.."$ \n\n **Time** : "..os.date("%Y/%m/%d %X"))
                end
                cb(true, "You sucesfully buyed "..houseid.." for "..price.."$.")
            end
        end)
    else
        cb(false, "You dont have enough money in the bank!")
    end
end)

ESX.RegisterServerCallback("nvm_house:savedata", function(source, cb, identifier, isowner, interior, houseid, x, y, z, intx, inty, intz, stashx, stashy, stashz)
    local data = {
        ['id'] = houseid,
        ['isowner'] = isowner,
        ['interior'] = interior,
        ['coords'] = vec3(x, y, z),
        ['icoords'] = vec3(intx, inty, intz),
        ['scoords'] = vec3(stashx, stashy, stashz)
    }
    entered[identifier] = data
    SaveData()
end)

ESX.RegisterServerCallback("nvm_house:getdata", function(source, cb, identifier)
    if entered[identifier] then
        local datas = {}
        table.insert(datas ,{
            id = entered[identifier].id,
            isowner = entered[identifier].isowner,
            interior = entered[identifier].interior,
            coords =  entered[identifier].coords,
            icoords = entered[identifier].icoords,
            scoords = entered[identifier].scoords
        })
        cb(datas)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback("nvm_house:cleardata", function(source, cb, identifier)
    if entered[identifier] ~= nil then
        entered[identifier] = nil
        SaveData()
    end
end)

RegisterServerEvent("nvm_house:setdimension")
AddEventHandler("nvm_house:setdimension", function(num)
    local xPlayer = ESX.GetPlayerFromId(source)
    SetPlayerRoutingBucket(xPlayer.source, tonumber(num))
end)

ESX.RegisterServerCallback("nvm_housingshell:openstash", function(source, cb, getid)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local identifier = xPlayer.getIdentifier()

    MySQL.Async.fetchScalar('SELECT id FROM nvm_houses WHERE id = @id AND (oidentifier = @oidentifier OR id IN (SELECT house_id FROM nvm_houses_keys WHERE identifier = @oidentifier))', {
        ['@id'] = getid,
        ['@oidentifier'] = identifier
    }, function(id)
        if id then
            exports.ox_inventory:RegisterStash(identifier..'_'..id, identifier..'_'..id, 250, 1025000, identifier..'_'..id, false, false)
            cb(identifier..'_'..id)
        end
    end)
end)

--KEYS

ESX.RegisterServerCallback("nvm_house:registerkey", function(source, cb, playerid, houseid, identifier2)
    local xPlayer = ESX.GetPlayerFromId(playerid)
    local identifier = xPlayer.getIdentifier()
    local player = xPlayer.getName()
    
    MySQL.Async.fetchScalar('SELECT oidentifier FROM nvm_houses WHERE id = @id AND oidentifier = @oidentifier', {
        ['@id'] = houseid,
        ['@oidentifier'] = identifier2
    }, function(ownerResult)
        if ownerResult then
            MySQL.Async.fetchScalar('SELECT identifier FROM nvm_houses_keys WHERE house_id = @id AND identifier = @oidentifier', {
                ['@id'] = houseid,
                ['@oidentifier'] = identifier
            }, function(result)
                if result then
                    cb(false)
                else
                    MySQL.Async.execute('INSERT INTO nvm_houses_keys (house_id, identifier, name) VALUES (@houseid, @identifier, @playername)', {
                        ['@houseid'] = houseid,
                        ['@identifier'] = identifier,
                        ['@playername'] = player
                    }, function(rowsChanged)
                        if rowsChanged > 0 then
                            cb(true, "Sucesfully added a key to "..player.." player")
                        else
                            cb(false, "There's been an error during key transfering..")
                        end
                    end)
                end
            end)
        else
            cb(false, "There's been an error during key transfering..")
        end
    end)
end)

ESX.RegisterServerCallback("nvm_house:getkeys", function(source, cb, houseId, identifier)
    MySQL.Async.fetchScalar('SELECT oidentifier FROM nvm_houses WHERE id = @id AND oidentifier = @oidentifier', {
        ['@id'] = houseId,
        ['@oidentifier'] = identifier
    }, function(ownerResult)
        if ownerResult then
            MySQL.Async.fetchAll('SELECT name FROM nvm_houses_keys WHERE house_id = @house_id', {
                ['@house_id'] = houseId
            }, function(result)
                local keys = {}

                for i=1, #result, 1 do
                    table.insert(keys, {
                        player_name = result[i].name
                    })
                end

                cb(keys)
            end)
        else
            cb(false, "Only the owner can get keys")
        end
    end)
end)

ESX.RegisterServerCallback("nvm_house:removekey", function(source, cb, houseId, playername)
    MySQL.Async.execute('DELETE FROM nvm_houses_keys WHERE house_id = @house_id AND name = @playername', {
        ['@house_id'] = houseId,
        ['@playername'] = playername
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', source, 'Key successfully removed from '..playername.." player")
        else
            TriggerClientEvent('esx:showNotification', source, 'ERROR??')
        end
    end)
end)


-- GARAGE PART
ESX.RegisterServerCallback("nvm_house:getownedcars", function(source, cb)
    local ownedcars = {}
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * from owned_vehicles WHERE owner = @owner AND type = @type AND stored = @stored', {
        ['@owner'] = xPlayer.identifier,
        ['@type'] = 'car',
        ['@stored'] = true
    }, function(data)
        for k,v in pairs(data) do
            local vehicle = json.decode(v.vehicle)
            table.insert(ownedcars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
        end
        cb(ownedcars)
    end)
end)

ESX.RegisterServerCallback("nvm_house:storecar", function(source, cb, vehicleprops)
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehiclemodel = vehicleprops.model

    MySQL.Async.fetchAll('SELECT * from owned_vehicles WHERE owner = @owner AND plate = @plate', {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = vehicleprops.plate
    }, function(result)
       if result[1] ~= nil then
            local originmodel = json.decode(result[1].vehicle)
            if originmodel.model == vehiclemodel then
                MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle WHERE owner = @owner AND plate = @plate',{
                    ['@owner'] = xPlayer.identifier,
                    ['@vehicle'] = json.encode(vehicleprops),
                    ['@plate'] = vehicleprops.plate
                }, function()
                    cb(true)
                end)
            else
                cb(false)
            end
       end
    end)
end)

RegisterServerEvent("nvm_house:setstatecar")
AddEventHandler("nvm_house:setstatecar", function(plate, state)
    local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate', {
		['@stored'] = state,
		['@plate'] = plate
	}, function()
	end)
end)

function sendToDiscord(title, message)
    local embed = {
        {
            ["color"] = 65280,
            ["title"] = "**".. Config.Name .." __ "..title.."**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = Config.Footer,
            },
        }
    }
    PerformHttpRequest(Config.WebHook, function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
  end