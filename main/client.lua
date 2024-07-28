ESX = exports['es_extended']:getSharedObject()

-- js /command
RegisterCommand(Config.Command, function(source)
    if not Config.Access[LocalPlayer.state.group] then
        Citizen.Wait(200)
        TriggerEvent('chat:addMessage', { color = { 255, 0, 0}, multiline = true, args = {"[Admin]", "Access denied for command house!"} })
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "ui",
        status = true
    })
end)
RegisterNUICallback("exit", function()
    SetNuiFocus(false, false)
end)
RegisterNUICallback("coords", function(data)
    local pped = PlayerPedId()
    local coords = GetEntityCoords(pped)
    local heading = GetEntityHeading(pped)

    if data.type == "house" then
        SendNUIMessage({
            type = "coords",
            status = "house",
            x = coords.x,
            y = coords.y,
            z = coords.z
        })
    elseif data.type == "garage" then
        SendNUIMessage({
            type = "coords",
            status = "garage",
            x = coords.x,
            y = coords.y,
            z = coords.z,
            h = heading
        })
    end
end)
RegisterNUICallback("datas", function(data)
    SetNuiFocus(false, false) 
    ESX.TriggerServerCallback("nvm_house:setuphouse", function(ifplayer, text)
        if ifplayer then
            ESX.ShowNotification("Successfully created house for "..text.." player")
        else
            ESX.ShowNotification("ERROR. Reason: "..text)
        end
    end, data.player, data.interior, data.house.x, data.house.y, data.house.z, data.garage.x, data.garage.y, data.garage.z, data.garage.h)
end)


-- Main housing part
local identifier = nil
Citizen.CreateThread(function()
    while not identifier do
        Citizen.Wait(5000)
        identifier = ESX.GetPlayerData().identifier
    end
    SetupBlip(identifier)
    SetupHouses(identifier)
end)

function SetupBlip(pidentifier)
    ESX.TriggerServerCallback("nvm_house:blips", function(ownerIdentifier, houses)
        if houses and ownerIdentifier == pidentifier then
            for k, v in ipairs(houses) do
                local blip = AddBlipForCoord(tonumber(v.coords.x), tonumber(v.coords.y), tonumber(v.coords.z))
                SetBlipSprite(blip, 40)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, 0.8)
                SetBlipColour(blip, 2)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("House ("..v.id..")")
                EndTextCommandSetBlipName(blip)
            end
        end
    end, pidentifier)
end

function SetupHouses(pidentifier)
    ESX.TriggerServerCallback("nvm_house:getallhouse", function(houses)
        if houses then
            for k,v in ipairs(houses) do
                local hx = tonumber(v.hcoords.x)
                local hy = tonumber(v.hcoords.y)
                local hz = tonumber(v.hcoords.z)
                Citizen.CreateThread(function()
                    while true do
                        Citizen.Wait(waittime)
                        local pped = PlayerPedId()
                        local pcoords = GetEntityCoords(pped, false)
                        local near = false
                        local dist = #(pcoords- vec3(hx, hy, hz))
                        if dist < 10.0 then
                            near = true
                            DrawMarker(22, hx, hy, hz, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 0, 255, 0, 100, 0, 0, 0, 1)
                        end
                        if dist < 1.0 then
                            DisplayHelpText("Press ~INPUT_CONTEXT~ to enter / ~INPUT_DETONATE~ close/open")
                            if IsControlJustPressed(0, 38) then
                                ESX.TriggerServerCallback("nvm_house:lockstatus", function(lockstate, isowner)
                                    if lockstate then
                                        ESX.ShowNotification("This house is closed.")
                                    else
                                        HouseState(pidentifier, "enter", isowner, v.interior, v.id, hx, hy, hz)
                                    end
                                end, pidentifier, v.id)
                            end
                            if IsControlJustPressed(0, 47) then
                                ToggleHouse(pidentifier, v.id, true)
                            end
                        end
                        local icoords = GetInterior(v.interior)
                        local dist2 = #(pcoords - vec3(icoords.x, icoords.y, icoords.z))
                        if dist2 < 5.0 then
                            near = true
                            DrawMarker(22, icoords.x, icoords.y, icoords.z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 255, 0, 0, 100, 0, 0, 0, 1)
                        end
                        if dist2 < 1.0 then
                            DisplayHelpText("Press ~INPUT_CONTEXT~ to leave / ~INPUT_DETONATE~ open/close")
                            if IsControlJustPressed(0, 38) then
                                ESX.TriggerServerCallback("nvm_house:getdata", function(table)
                                    if table then
                                        for k,data in ipairs(table) do
                                            ESX.TriggerServerCallback("nvm_house:lockstatus", function(lockstate, isowner)
                                                if lockstate then
                                                    --Trying to fix this gap
                                                else
                                                    HouseState(pidentifier, "leave", isowner, data.interior, data.id, data.coords.x, data.coords.y, data.coords.z)
                                                end
                                            end, pidentifier, data.id)
                                        end
                                    end
                                end, pidentifier)
                            end
                            if IsControlJustPressed(0, 47) then
                                ESX.TriggerServerCallback("nvm_house:getdata", function(table)
                                    if table then
                                        for k,data in ipairs(table) do
                                            ToggleHouse(pidentifier, data.id, false)
                                        end
                                    end
                                end, pidentifier)
                            end
                        end
                        if near then
                            waittime = 0
                        else
                            waittime = 1500
                        end
                    end
                end)
            end
        end
    end)
    
    ESX.TriggerServerCallback("nvm_house:getownerhouse", function(house)
        if house then
            for _,data in ipairs(house) do
                local gx = tonumber(data.gcoords.x)
                local gy = tonumber(data.gcoords.y)
                local gz = tonumber(data.gcoords.z)
                local gh = tonumber(data.gcoords.h)
                Citizen.CreateThread(function()
                    while true do
                        Citizen.Wait(waittime2)
                        local pped = PlayerPedId()
                        local pcoords = GetEntityCoords(pped, false)
                        local near2 = false
                        local dist3 = #(pcoords - vec3(gx, gy, gz))
                        if dist3 < 5.0 then
                            near2 = true
                            DrawMarker(36, gx, gy, gz, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 1.0, 0, 0, 255, 75, 0, 0, 0, 1)
                        end
                        if dist3 < 1.0 then
                            if not Menu.hidden then
                                Menu.renderGUI()
                                if IsControlJustPressed(1, Keys["ESC"]) or  IsControlJustPressed(1, Keys["BACKSPACE"]) then
                                    CloseMenu()
                                end
                            end
                            if IsPedInAnyVehicle(pped, false) then
                                DisplayHelpText("Press ~INPUT_CONTEXT~ to store vehicle")
                                if IsControlJustPressed(0, 38) then
                                    MenuGarage("store", gx, gy, gz, gh)
                                end
                            else
                                DisplayHelpText("Press ~INPUT_CONTEXT~ to open garage")
                                if IsControlJustPressed(0, 38) then
                                    MenuGarage("garage", gx, gy, gz, gh)
                                end
                            end
                        end
                        local scoords = GetStorage(data.interior)
                        local dist4 = #(pcoords - vec3(scoords.x, scoords.y, scoords.z))
                        if dist4 < 5.0 then
                            near2 = true
                            DrawMarker(29, scoords.x, scoords.y, scoords.z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5001, 255, 0, 0, 200, 0, 0, 0, 1)
                        end
                        if dist4 < 0.5 then
                            if IsControlJustPressed(0, 38) then
                                ESX.TriggerServerCallback("nvm_housingshell:openstash", function(stashId)
                                    exports.ox_inventory:openInventory('stash', {id=stashId, owner=stashId})
                                end, data.id)
                            end
                        end
                        if near2 then
                            waittime2 = 0
                        else
                            waittime2 = 1500
                        end
                    end
                end)
                
            end
        end
    end, pidentifier)
end

function HouseState(pidentifier, action, isowner, interior, houseid, x , y, z)
    if action == "enter" then
        if isowner then
            elements = {
                {label = "Enter", name = "tpin"},
                {label = "Add key", name = "keyadd"},
                {label = 'Keys', name = "keys"}
            }
        else
            elements = {
                {label = "Enter", name = "tpin"}
            }
        end
    elseif action == "leave" then
        if isowner then
            elements = {
                {label = "Leave", name = "tpout"},
                {label = "Add key", name = "keyadd"},
                {label = 'Keys', name = "keys"}
            }
        else
            elements = {
                {label = "Leave", name = "tpout"}
            }
        end
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'nvm_house', {
        title    = 'House - NUM: '..houseid.." (INT: "..interior..")",
        align    = 'center',
        elements = elements
    }, function(data, menu)
        if data.current.name == "tpin" then
            menu.close()
            local icoords = GetInterior(interior)
            DoScreenFadeOut(1000)
            Citizen.Wait(1000)
            SetEntityCoords(PlayerPedId(), icoords.x, icoords.y, icoords.z, 0, 0, 0)
            TriggerServerEvent("nvm_house:setdimension", houseid)
            DoScreenFadeIn(1000)
            ESX.TriggerServerCallback("nvm_house:savedata", function()                                                
            end, pidentifier, interior, houseid, x, y, z)
        elseif data.current.name == "tpout" then
            menu.close()
            DoScreenFadeOut(1000)
            Citizen.Wait(1000)
            SetEntityCoords(PlayerPedId(), x, y, z, 0, 0, 0)
            TriggerServerEvent("nvm_house:setdimension", 0)
            DoScreenFadeIn(1000)
            ESX.TriggerServerCallback("nvm_house:cleardata", function()
                                                
            end, pidentifier)
        elseif data.current.name == "keyadd" then
            menu.close()
            local playeradd = KeyboardInput("Who do you want to give a key to? (ID)", "", 4)
            if tonumber(playeradd) and tonumber(playeradd) > 0 and tonumber(playeradd) ~= GetPlayerServerId(PlayerId()) then
                ESX.TriggerServerCallback("nvm_house:registerkey", function(state, text)
                    if state then
                        ESX.ShowNotification("Key Successfully added to "..text)
                    else
                        ESX.ShowNotification("There's been an error during key transfering..")
                    end
                end, tonumber(playeradd), houseid, pidentifier)
            else
                ESX.ShowNotification("You can't give a key for yourself or wrong ID")
            end
        elseif data.current.name == "keys" then
            ESX.TriggerServerCallback("nvm_house:getkeys", function(keys)
                local keyElements = {}

                if #keys == 0 then
                    table.insert(keyElements, {label = ""})
                else
                    for _, key in ipairs(keys) do
                        table.insert(keyElements, {label = key.player_name, value = key.player_name})
                    end
                end
                ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'nvm_house_keys', {
                    title    = 'Keys',
                    align    = 'center',
                    elements = keyElements
                }, function(data2, menu2)
                    local selectedKey = data2.current.value
                    if selectedKey then
                        ESX.TriggerServerCallback("nvm_house:removekey", function()
                        end, houseid, selectedKey)
                        menu2.close()
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            end, houseid, pidentifier)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function ToggleHouse(pidentifier, houseid, notify)
    ESX.TriggerServerCallback("nvm_house:housetoggle", function(newState)
        if newState then
            if notify then
                ESX.ShowNotification("Successfully Closed the House.")
            end
        else
            if notify then
                ESX.ShowNotification("Successfully Opened the House.")
            end
        end
    end, pidentifier, houseid)
end

-- Main housing part END

-- GARAGE
function MenuGarage(action, x, y, z, h)
	if action == "garage" then
		ESX.TriggerServerCallback('nvm_house:getownedcars', function(ownedCars)
			ClearMenu()
			local count = 0
			for _, vehicle in pairs(ownedCars) do
				count = count + 1
			end
    		MenuTitle = "Garage2"
			Menu.addButton("My cars - ("..count..")", "OpenMenuGarage", {x1 = x, y1 = y, z1 = z, h1 = h}, nil)
            Menu.addButton("Close", "CloseMenu", nil, nil)
			Menu.hidden = false
		end)
    elseif action == "store" then
        local playerPed  = GetPlayerPed(-1)

        if IsPedInAnyVehicle(playerPed,  false) then
            local playerPed = GetPlayerPed(-1)
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
    
            ESX.TriggerServerCallback('nvm_house:storecar', function(valid)
                if valid then
                    ESX.Game.DeleteVehicle(vehicle)
	                TriggerServerEvent('nvm_house:setstatecar', vehicleProps.plate, true)
	                
                else
                    ESX.Game.DeleteVehicle(vehicle)
                end
            end, vehicleProps)
        end
	end
end

local currentPage = 1
local vehiclesPerPage = 20

function OpenMenuGarage(action, page)
    currentPage = page or 1
    ClearMenu()
    
    local x2 = action.x1
    local y2 = action.y1
    local z2 = action.z1
    local h2 = action.h1
    MenuTitle = "Garage2"
    ESX.TriggerServerCallback('nvm_house:getownedcars', function(ownedCars)
        local count = 0
        local nonFavoriteCars = {}
        for _, vehicle in pairs(ownedCars) do
            if not vehicle.favorite then
                count = count + 1
                table.insert(nonFavoriteCars, vehicle)
            end
        end
        Menu.addButton("My cars - ("..count..")", nil, nil, nil)
        
        local startIndex = (currentPage - 1) * vehiclesPerPage + 1
        local endIndex = math.min(startIndex + vehiclesPerPage - 1, count)
        for i = startIndex, endIndex do
            local vehicle = nonFavoriteCars[i]
            if vehicle then
                local hashVehicule = vehicle.vehicle.model
                local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
                local vehicleName = GetLabelText(aheadVehName)
                local name = vehicle.plate .. " | " .. vehicleName .. " | HP: " .. round(vehicle.vehicle.engineHealth) / 10 .. "%"
                local tank = "Fuel: " .. round(vehicle.vehicle.fuelLevel) .. "%"
                Menu.addButton(name, "OptionVehicle", { mode = "garage", vehicle = vehicle.vehicle, model = vehicle.vehicle.model, plate = vehicle.plate, x3 = x2, y3 = y2, z3 = z2, h3 = h2}, tank)
            end
        end
		
        if currentPage >= 1 then
            Menu.addButton("Next Page", nil, nil, nil)
        end
        if endIndex < count then
            Menu.addButton("Next Page", "nextPage", action, nil)
        end
        Menu.addButton("Back", "MenuGarage", "garage", nil)
        Menu.hidden = false
    end)
end

function prevPage(action)
    if currentPage > 1 then
        OpenMenuGarage(action, currentPage - 1)
    end
end

function nextPage(action)
    ESX.TriggerServerCallback('nvm_house:getownedcars', function(vehicles)
        local count = 0
        for _, vehicle in pairs(vehicles) do
            count = count + 1
        end

        local maxPage = math.ceil(count / vehiclesPerPage)
        if currentPage < maxPage then
            OpenMenuGarage(action, currentPage + 1)
        end
    end)
end

function OptionVehicle(data)
    MenuTitle = "Options :2"
    ClearMenu()
    Menu.addButton("Spawn", "SpawnVehicle", data, nil)
    Menu.addButton("Back", "OpenGarageMenu", nil, nil)
end

function SpawnVehicle(vehicle)
    ESX.Game.SpawnVehicle(vehicle.model, vec3(vehicle.x3, vehicle.y3, vehicle.z3), vehicle.h3, function(callback_vehicle)
        ESX.Game.SetVehicleProperties(callback_vehicle, vehicle.vehicle)
        SetVehRadioStation(callback_vehicle, "OFF")
		exports["LegacyFuel"]:SetFuel(callback_vehicle, vehicle.vehicle.fuelLevel)
		SetVehicleEngineHealth(callback_vehicle, vehicle.vehicle.engineHealth)
        --SetVehicleFixed(callback_vehicle)
        --SetVehicleDeformationFixed(callback_vehicle)
        SetVehicleUndriveable(callback_vehicle, false)
        TaskWarpPedIntoVehicle(GetPlayerPed(-1), callback_vehicle, -1)
    end)
    TriggerServerEvent('nvm_house:setstatecar', vehicle.plate, false)
	CloseMenu()
end
-- GARAGE END

-- Functions


function GetInterior(number)
    local interiors = {
        ["1"] = {x = 151.52967834473, y = -1007.6175537109, z = -99.0146484375},
        ["2"] = {x = -270.89498901367, y = -968.07769775391, z = 77.231323242188}, 
        ["3"] = {x = 346.53625488281, y = -1012.6549682617, z = -99.199951171875},
        ["4"] = {x = -30.659961700439, y = -595.28381347656, z = 80.030876159668},
        ["5"] = {x = -17.548027038574, y = -588.68542480469, z = 90.114822387695},
        ["6"] = {x = -174.29681396484, y = 497.44467163086, z = 137.66700744629},
        ["7"] = {x = 117.2368927002, y = 559.15655517578, z = 184.30490112305},
    }
    return interiors[tostring(number)]
end

function GetStorage(number)
    local stashlocations = {
        ["1"] = {x = 151.436, y = -1003.093, z = -98.999},
        ["2"] = {x = -268.606, y = -940.823, z = 75.828},
        ["3"] = {x = 351.304, y = -998.943, z = -99.196},
        ["4"] = {x = -28.262, y = -583.349, z = 79.230},
        ["5"] = {x = -44.670, y = -586.756, z = 88.712},
        ["6"] = {x = -171.145, y = 487.010, z = 137.443},
        ["7"] = {x = 118.541, y = 547.0412, z = 184.096},
    }
    return stashlocations[tostring(number)]
end

function DisplayHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, 0, 1, -1)
end

function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    blockinput = true

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500)
        blockinput = false
        return result
    else
        Citizen.Wait(500)
        blockinput = false
        return nil
    end
end

function round(n)
    if not n then return 0; end
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

--  G U I  -- Don't touch unless you know what to do...
Keys = {
    ["ESC"] = 322, ["DOWN"] = 173, ["TOP"] = 27, ["ENTER"] = 18, ["BACKSPACE"] = 177
}
Menu = {}
Menu.GUI = {}
Menu.buttonCount = 0
Menu.selection = 0
Menu.hidden = true
MenuTitle = "Menu2"
function Menu.addButton(name, func, args, tank, extra)
    local yoffset = 0.25
    local xoffset = 0.3
    local xmin = 0.0
    local xmax = 0.15
    local ymin = 0.03
    local ymax = 0.03
    Menu.GUI[Menu.buttonCount+1] = {}
    Menu.GUI[Menu.buttonCount+1]["name"] = name
    Menu.GUI[Menu.buttonCount+1]["func"] = func
    Menu.GUI[Menu.buttonCount+1]["args"] = args
	if tank ~= nil then
    Menu.GUI[Menu.buttonCount+1]["tank"] = tank
	Menu.GUI[Menu.buttonCount+1]["extra"] = extra
	end
    Menu.GUI[Menu.buttonCount+1]["active"] = false
    Menu.GUI[Menu.buttonCount+1]["xmin"] = xmin
    Menu.GUI[Menu.buttonCount+1]["ymin"] = ymin * (Menu.buttonCount + 0.01) + yoffset
    Menu.GUI[Menu.buttonCount+1]["xmax"] = xmax 
    Menu.GUI[Menu.buttonCount+1]["ymax"] = ymax 
    Menu.buttonCount = Menu.buttonCount + 1
end
function Menu.updateSelection()
    if IsControlJustPressed(1, Keys["DOWN"]) then 
        if (Menu.selection < Menu.buttonCount - 1) then
            Menu.selection = Menu.selection + 1
        else
            Menu.selection = 0
        end
        PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
    elseif IsControlJustPressed(1, Keys["TOP"]) then
        if (Menu.selection > 0) then
            Menu.selection = Menu.selection - 1
        else
            Menu.selection = Menu.buttonCount - 1
        end
        PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
    elseif IsControlJustPressed(1, Keys["ENTER"]) then
        if Menu.GUI[Menu.selection + 1] and Menu.GUI[Menu.selection + 1]["func"] then
            MenuCallFunction(Menu.GUI[Menu.selection + 1]["func"], Menu.GUI[Menu.selection + 1]["args"])
        end
        PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
    end

    for id, settings in ipairs(Menu.GUI) do
        settings["active"] = false
        if id == Menu.selection + 1 then
            settings["active"] = true
        end
    end
end
function Menu.renderGUI()
    if not Menu.hidden then
        Menu.renderButtons()
        Menu.updateSelection()
    end
end
function Menu.renderButtons()
    for id, settings in pairs(Menu.GUI) do
        local boxColor = {13, 11, 10, 233}
        if settings["active"] then
            boxColor = {45, 45, 45, 230}
        end
		if settings["tank" ] ~= nil then
        	--NAME BG
        	DrawRect(0.7, settings["ymin"], 0.15, settings["ymax"] - 0.002, boxColor[1], boxColor[2], boxColor[3], boxColor[4])
        	--NAME
        	SetTextFont(4)
        	SetTextScale(0.34, 0.34)
        	SetTextColour(255, 255, 255, 255)
        	SetTextEntry("STRING")
        	AddTextComponentString(settings["name"])
        	DrawText(0.63, (settings["ymin"] - 0.012))
        	--TANK BG
        	DrawRect(0.832, settings["ymin"], 0.11, settings["ymax"] - 0.002, 255, 255, 255, 199)
        	--TANK
        	SetTextFont(4)
        	SetTextScale(0.34, 0.34)
        	SetTextColour(0, 0, 0, 255)
        	SetTextEntry("STRING")
        	AddTextComponentString(settings["tank"])
        	DrawText(0.845, (settings["ymin"] - 0.012))
			--EXTRA
			SetTextFont(4)
        	SetTextScale(0.34, 0.34)
        	SetTextColour(0, 0, 0, 255)
        	SetTextEntry("STRING")
        	AddTextComponentString(settings["extra"])
        	DrawText(0.780, (settings["ymin"] - 0.012))
		else
			DrawRect(0.7, settings["ymin"], 0.15, settings["ymax"] - 0.002, boxColor[1], boxColor[2], boxColor[3], boxColor[4])
			SetTextFont(4)
			SetTextScale(0.34, 0.34)
			SetTextColour(255, 255, 255, 255)
			SetTextCentre(true)
			SetTextEntry("STRING") 
			AddTextComponentString(settings["name"])
			DrawText(0.7, (settings["ymin"] - 0.012 )) 
		end
    end     
end
function ClearMenu()
    Menu.GUI = {}
    Menu.buttonCount = 0
    Menu.selection = 0
end
function MenuCallFunction(fnc, arg)
    _G[fnc](arg)
end
function CloseMenu()
    Menu.hidden = true
    ClearMenu()
end