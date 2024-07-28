ESX = exports['es_extended']:getSharedObject()

--Housing System
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

ESX.RegisterServerCallback("nvm_house:setuphouse", function(source, cb, player, interior, housex, housey, housez, garagex, garagey, garagez, garageh)
    local xPlayer = ESX.GetPlayerFromId(tonumber(player))
    
    if xPlayer then
        local identifier = xPlayer.identifier
        local housecoords = json.encode({x=housex, y=housey, z=housez})
        local garagecoords = json.encode({x=garagex, y=garagey, z=garagez, h=garageh})
        
        MySQL.Async.execute('INSERT INTO nvm_houses (owner, house_coords, garage_coords, interior, is_locked) VALUES (@identifier, @housecoords, @garagecoords, @interior, @islocked)', {
            ['@identifier'] = identifier,
            ['@housecoords'] = housecoords,
            ['@garagecoords'] = garagecoords,
            ['@interior'] = interior,
            ['@islocked'] = true
        }, function(rowsChanged)
            if rowsChanged > 0 then
                local houseId = MySQL.Sync.fetchScalar('SELECT id FROM nvm_houses WHERE owner = @identifier AND house_coords = @housecoords', {
                    ['@identifier'] = identifier,
                    ['@housecoords'] = housecoords
                })
                cb(true, identifier)
            else
                cb(false, "Same Data?-")
            end
        end)
    else
        cb(false, "Player ID not found.")
    end
end)

ESX.RegisterServerCallback("nvm_house:getallhouse", function(source, cb)
    MySQL.Async.fetchAll('SELECT * FROM nvm_houses', {}, function(results)
        local houses = {}
        for i=1, #results, 1 do
            table.insert(houses, {
                id = results[i].id,
                hcoords = json.decode(results[i].house_coords),
                gcoords = json.decode(results[i].garage_coords),
                interior = results[i].interior,
                locked = results[i].is_locked
            })
        end
        cb(houses)
    end)
end)

ESX.RegisterServerCallback("nvm_house:getownerhouse", function(source, cb, identifier)
    MySQL.Async.fetchAll('SELECT * FROM nvm_houses WHERE owner = @owner OR id IN (SELECT house_id FROM nvm_houses_keys WHERE player_identifier = @owner)', {
        ['@owner'] = identifier
    }, function(results)
        local houses = {}
        for i=1, #results, 1 do
            table.insert(houses, {
                id = results[i].id,
                hcoords = json.decode(results[i].house_coords),
                gcoords = json.decode(results[i].garage_coords),
                interior = results[i].interior,
                locked = results[i].is_locked
            })
        end
        cb(houses)
    end)
end)

ESX.RegisterServerCallback("nvm_house:blips", function(source, cb, identifier)
    MySQL.Async.fetchAll('SELECT id, house_coords FROM nvm_houses WHERE owner = @owner OR id IN (SELECT house_id FROM nvm_houses_keys WHERE player_identifier = @owner)', {
        ['@owner'] = identifier
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
    MySQL.Async.fetchAll('SELECT is_locked, owner FROM nvm_houses WHERE id = @id', {
        ['@id'] = houseid
    }, function(house)
        if house[1] then
            local isLocked = house[1].is_locked
            local isOwner = house[1].owner == identifier

            MySQL.Async.fetchAll('SELECT house_id FROM nvm_houses_keys WHERE house_id = @id AND player_identifier = @owner', {
                ['@id'] = houseid,
                ['@owner'] = identifier
            }, function(keys)
                local isCoOwner = #keys > 0
                if isLocked then
                    cb(true, isOwner or isCoOwner)
                else
                    cb(false, isOwner or isCoOwner)
                end
            end)
        else
            cb(false, false)
        end
    end)
end)

ESX.RegisterServerCallback("nvm_house:housetoggle", function(source, cb, identifier, houseid)
    MySQL.Async.fetchAll('SELECT is_locked FROM nvm_houses WHERE id = @id AND (owner = @owner OR id IN (SELECT house_id FROM nvm_houses_keys WHERE player_identifier = @owner))', {
        ['@id'] = houseid,
        ['@owner'] = identifier
        
    }, function(result)
        if result[1] then
            local currentState = result[1].is_locked
            if currentState then
                newState = false
            
            else
                newState = true
            end
            MySQL.Async.execute('UPDATE nvm_houses SET is_locked = @newState WHERE id = @id AND (owner = @owner OR id IN (SELECT house_id FROM nvm_houses_keys WHERE player_identifier = @owner))', {
                ['@newState'] = newState,
                ['@id'] = houseid,
                ['@owner'] = identifier
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    cb(newState)
                end
            end)
        end
    end)
end)

RegisterServerEvent("nvm_house:setdimension")
AddEventHandler("nvm_house:setdimension", function(num)
    local xPlayer = ESX.GetPlayerFromId(source)
    SetPlayerRoutingBucket(xPlayer.source, tonumber(num))
end)

ESX.RegisterServerCallback("nvm_house:savedata", function(source, cb, identifier, interior, houseid, x, y, z)
    local data = {
        ['id'] = houseid,
        ['interior'] = interior,
        ['coords'] = vec3(x, y, z)
    }
    entered[identifier] = data
    SaveData()
end)

ESX.RegisterServerCallback("nvm_house:getdata", function(source, cb, identifier)
    if entered[identifier] then
        local datas = {}
        table.insert(datas ,{
            id = entered[identifier].id,
            interior = entered[identifier].interior,
            coords =  entered[identifier].coords
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

ESX.RegisterServerCallback("nvm_housingshell:openstash", function(source, cb, getid)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local identifier = xPlayer.getIdentifier()

    MySQL.Async.fetchScalar('SELECT id FROM nvm_houses WHERE id = @id AND (owner = @owner OR id IN (SELECT house_id FROM nvm_houses_keys WHERE player_identifier = @owner))', {
        ['@id'] = getid,
        ['@owner'] = identifier
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
    
    MySQL.Async.fetchScalar('SELECT owner FROM nvm_houses WHERE id = @id AND owner = @owner', {
        ['@id'] = houseid,
        ['@owner'] = identifier2
    }, function(ownerResult)
        if ownerResult then
            MySQL.Async.fetchScalar('SELECT player_identifier FROM nvm_houses_keys WHERE house_id = @id AND player_identifier = @owner', {
                ['@id'] = houseid,
                ['@owner'] = identifier
            }, function(result)
                if result then
                    cb(false)
                else
                    MySQL.Async.execute('INSERT INTO nvm_houses_keys (house_id, player_identifier, player_name) VALUES (@houseid, @identifier, @playername)', {
                        ['@houseid'] = houseid,
                        ['@identifier'] = identifier,
                        ['@playername'] = player
                    }, function(rowsChanged)
                        if rowsChanged > 0 then
                            cb(true, player)
                        else
                            cb(false, nil)
                        end
                    end)
                end
            end)
        else
            cb(false, nil)
        end
    end)
end)

ESX.RegisterServerCallback("nvm_house:getkeys", function(source, cb, houseId, identifier)
    MySQL.Async.fetchScalar('SELECT owner FROM nvm_houses WHERE id = @id AND owner = @owner', {
        ['@id'] = houseId,
        ['@owner'] = identifier
    }, function(ownerResult)
        if ownerResult then
            MySQL.Async.fetchAll('SELECT player_name FROM nvm_houses_keys WHERE house_id = @house_id', {
                ['@house_id'] = houseId
            }, function(result)
                local keys = {}

                for i=1, #result, 1 do
                    table.insert(keys, {
                        player_name = result[i].player_name
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
    MySQL.Async.execute('DELETE FROM nvm_houses_keys WHERE house_id = @house_id AND player_name = @playername', {
        ['@house_id'] = houseId,
        ['@playername'] = playername
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', source, 'Key successfully removed')
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