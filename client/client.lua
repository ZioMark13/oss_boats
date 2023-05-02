local VORPcore = {}
-- Prompts
local OpenShops
local CloseShops
local OpenReturn
local CloseReturn
local ShopPrompt1 = GetRandomIntInRange(0, 0xffffff)
local ShopPrompt2 = GetRandomIntInRange(0, 0xffffff)
local ReturnPrompt1 = GetRandomIntInRange(0, 0xffffff)
local ReturnPrompt2 = GetRandomIntInRange(0, 0xffffff)
-- Jobs
local PlayerJob
local JobName
local JobGrade
-- Boats
local ShopName
local ShowroomBoat_entity
local MyBoat_entity
local MyBoat = nil
local MyBoatId
local isAnchored
local BoatCam
local ShopId
--Menu
local InMenu = false
MenuData = {}

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

TriggerEvent("menuapi:getData", function(call)
    MenuData = call
end)

-- Start Boats
Citizen.CreateThread(function()
    ShopOpen()
    ShopClosed()
    ReturnOpen()
    ReturnClosed()

    while true do
        Citizen.Wait(0)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local sleep = true
        local dead = IsEntityDead(player)
        local hour = GetClockHours()

        if InMenu == false and not dead then
            for shopId, shopConfig in pairs(Config.boatShops) do
                if shopConfig.shopHours then
                    -- Using Shop Hours - Shop Closed
                    if hour >= shopConfig.shopClose or hour < shopConfig.shopOpen then
                        if Config.blipAllowedClosed then
                            if not Config.boatShops[shopId].BlipHandle and shopConfig.blipAllowed then
                                AddBlip(shopId)
                            end
                        else
                            if Config.boatShops[shopId].BlipHandle then
                                RemoveBlip(Config.boatShops[shopId].BlipHandle)
                                Config.boatShops[shopId].BlipHandle = nil
                            end
                        end
                            if Config.boatShops[shopId].BlipHandle then
                                Citizen.InvokeNative(0x662D364ABF16DE2F, Config.boatShops[shopId].BlipHandle, joaat(shopConfig.blipColorClosed)) -- BlipAddModifier
                            end
                            if shopConfig.NPC then
                                DeleteEntity(shopConfig.NPC)
                                DeletePed(shopConfig.NPC)
                                SetEntityAsNoLongerNeeded(shopConfig.NPC)
                                shopConfig.NPC = nil
                        end
                        local coordsDist = vector3(coords.x, coords.y, coords.z)
                        local coordsShop = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z)
                        local coordsBoat = vector3(shopConfig.spawn.x, shopConfig.spawn.y, shopConfig.spawn.z)
                        local distanceShop = #(coordsDist - coordsShop)
                        local distanceBoat = #(coordsDist - coordsBoat)

                        if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                            sleep = false
                            local shopClosed = CreateVarString(10, 'LITERAL_STRING', shopConfig.shopName .. _U("closed"))
                            PromptSetActiveGroupThisFrame(ShopPrompt2, shopClosed)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, CloseShops) then -- UiPromptHasStandardModeCompleted

                                Wait(100)
                                VORPcore.NotifyRightTip(shopConfig.shopName .. _U("hours") .. shopConfig.shopOpen .. _U("to") .. shopConfig.shopClose .. _U("hundred"), 5000)
                            end
                        elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                            sleep = false
                            local returnClosed = CreateVarString(10, 'LITERAL_STRING', shopConfig.shopName .. _U("closed"))
                            PromptSetActiveGroupThisFrame(ReturnPrompt2, returnClosed)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, CloseReturn) then -- UiPromptHasStandardModeCompleted

                                Wait(100)
                                VORPcore.NotifyRightTip(shopConfig.shopName .. _U("hours") .. shopConfig.shopOpen .. _U("to") .. shopConfig.shopClose .. _U("hundred"), 5000)
                            end
                        end
                    elseif hour >= shopConfig.shopOpen then
                        -- Using Shop Hours - Shop Open
                        if not Config.boatShops[shopId].BlipHandle and shopConfig.blipAllowed then
                            AddBlip(shopId)
                        end
                        if not shopConfig.NPC and shopConfig.npcAllowed then
                            SpawnNPC(shopId)
                        end
                        if not next(shopConfig.allowedJobs) then
                            if Config.boatShops[shopId].BlipHandle then
                                Citizen.InvokeNative(0x662D364ABF16DE2F, Config.boatShops[shopId].BlipHandle, joaat(shopConfig.blipColorOpen)) -- BlipAddModifier
                            end
                            local coordsDist = vector3(coords.x, coords.y, coords.z)
                            local coordsShop = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z)
                            local coordsBoat = vector3(shopConfig.spawn.x, shopConfig.spawn.y, shopConfig.spawn.z)
                            local distanceShop = #(coordsDist - coordsShop)
                            local distanceBoat = #(coordsDist - coordsBoat)

                            if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                                sleep = false
                                local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ShopPrompt1, shopOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenShops) then -- UiPromptHasStandardModeCompleted

                                    OpenMenu(shopId)
                                    DisplayRadar(false)
                                    TaskStandStill(player, -1)
                                end
                            elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                                sleep = false
                                local returnOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ReturnPrompt1, returnOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenReturn) then -- UiPromptHasStandardModeCompleted

                                        ReturnBoat(shopId)
                                end
                            end
                        else
                            -- Using Shop Hours - Shop Open - Job Locked
                            if Config.boatShops[shopId].BlipHandle then
                                Citizen.InvokeNative(0x662D364ABF16DE2F, Config.boatShops[shopId].BlipHandle, joaat(shopConfig.blipColorJob)) -- BlipAddModifier
                            end
                            local coordsDist = vector3(coords.x, coords.y, coords.z)
                            local coordsShop = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z)
                            local coordsBoat = vector3(shopConfig.spawn.x, shopConfig.spawn.y, shopConfig.spawn.z)
                            local distanceShop = #(coordsDist - coordsShop)
                            local distanceBoat = #(coordsDist - coordsBoat)

                            if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                                sleep = false
                                local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ShopPrompt1, shopOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenShops) then -- UiPromptHasStandardModeCompleted

                                    TriggerServerEvent("oss_boats:getPlayerJob")
                                    Wait(200)
                                    if PlayerJob then
                                        if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                            if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                                OpenMenu(shopId)
                                                DisplayRadar(false)
                                                TaskStandStill(player, -1)
                                            else
                                                VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                            end
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                    end
                                end
                            elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                                sleep = false
                                local returnOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptSetActiveGroupThisFrame(ReturnPrompt1, returnOpen)

                                if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenReturn) then -- UiPromptHasStandardModeCompleted

                                    ReturnBoat(shopId)
                                end
                            end
                        end
                    end
                else
                    -- Not Using Shop Hours - Shop Always Open
                    if not Config.boatShops[shopId].BlipHandle and shopConfig.blipAllowed then
                        AddBlip(shopId)
                    end
                    if not shopConfig.NPC and shopConfig.npcAllowed then
                        SpawnNPC(shopId)
                    end
                    if not next(shopConfig.allowedJobs) then
                        if Config.boatShops[shopId].BlipHandle then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, Config.boatShops[shopId].BlipHandle, joaat(shopConfig.blipColorOpen)) -- BlipAddModifier
                        end
                        local coordsDist = vector3(coords.x, coords.y, coords.z)
                        local coordsShop = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z)
                        local coordsBoat = vector3(shopConfig.spawn.x, shopConfig.spawn.y, shopConfig.spawn.z)
                        local distanceShop = #(coordsDist - coordsShop)
                        local distanceBoat = #(coordsDist - coordsBoat)

                        if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                            sleep = false
                            local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ShopPrompt1, shopOpen)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenShops) then -- UiPromptHasStandardModeCompleted

                                OpenMenu(shopId)
                                DisplayRadar(false)
                                TaskStandStill(player, -1)
                            end
                        elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                            sleep = false
                            local returnOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ReturnPrompt1, returnOpen)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenReturn) then -- UiPromptHasStandardModeCompleted

                                ReturnBoat(shopId)
                            end
                        end
                    else
                        -- -- Not Using Shop Hours - Shop Always Open - Job Locked
                        if Config.boatShops[shopId].BlipHandle then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, Config.boatShops[shopId].BlipHandle, joaat(shopConfig.blipColorJob)) -- BlipAddModifier
                        end
                        local coordsDist = vector3(coords.x, coords.y, coords.z)
                        local coordsShop = vector3(shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z)
                        local coordsBoat = vector3(shopConfig.spawn.x, shopConfig.spawn.y, shopConfig.spawn.z)
                        local distanceShop = #(coordsDist - coordsShop)
                        local distanceBoat = #(coordsDist - coordsBoat)

                        if (distanceShop <= shopConfig.distanceShop) and not IsPedInAnyBoat(player) then
                            sleep = false
                            local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ShopPrompt1, shopOpen)

                            if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenShops) then -- UiPromptHasStandardModeCompleted

                                TriggerServerEvent("oss_boats:getPlayerJob")
                                Wait(200)
                                if PlayerJob then
                                    if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                        if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                            OpenMenu(shopId)
                                            DisplayRadar(false)
                                            TaskStandStill(player, -1)
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                    end
                                else
                                    VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade,5000)
                                end
                            end
                        elseif (distanceBoat <= shopConfig.distanceReturn) and IsPedInAnyBoat(player) then
                            sleep = false
                            local returnOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptSetActiveGroupThisFrame(ReturnPrompt1, returnOpen)
                            if Citizen.InvokeNative(0xC92AC953F0A982AE, OpenReturn) then -- UiPromptHasStandardModeCompleted

                                ReturnBoat(shopId)
                            end
                        end
                    end
                end
            end
        end
        if sleep then
            Citizen.Wait(1000)
        end
    end
end)

-- Open Main Menu
function OpenMenu(shopId)
    InMenu = true
    ShopId = shopId
    ShopName = Config.boatShops[ShopId].shopName

    CreateCamera()

    TriggerServerEvent('oss_boats:GetMyBoats')
end

-- Get Boat Data for Players Boats
RegisterNetEvent('oss_boats:BoatsData')
AddEventHandler('oss_boats:BoatsData', function(data)

    SendNUIMessage({
        action = "show",
        shopBoats = Config.boatShops[ShopId].boats,
        location = ShopName,
        myBoats = data
    })
    SetNuiFocus(true, true)
end)

-- View Boats for Purchase
RegisterNUICallback("LoadBoat", function(data, cb)
    if MyBoat_entity ~= nil then
        DeleteEntity(MyBoat_entity)
        MyBoat_entity = nil
    end

    local model = joaat(data.BoatModel)
    LoadBoatModel(model)

    if ShowroomBoat_entity ~= nil then
        DeleteEntity(ShowroomBoat_entity)
        ShowroomBoat_entity = nil
    end

    if model ~= "keelboat" then
        SetCamFov(BoatCam, 50.0)
    else
        SetCamFov(BoatCam, 80.0)
    end
    local shopConfig = Config.boatShops[ShopId]
    ShowroomBoat_entity = CreateVehicle(model, shopConfig.spawn.x, shopConfig.spawn.y, shopConfig.spawn.z, shopConfig.spawn.h, false, false)
    Citizen.InvokeNative(0x7263332501E07F52, ShowroomBoat_entity, true) -- SetVehicleOnGroundProperly
    Citizen.InvokeNative(0x7D9EFB7AD6B19754, ShowroomBoat_entity, true) -- FreezeEntityPosition
    cb('ok')
end)

-- Buy and Name New Boat
RegisterNUICallback("BuyBoat", function(data, cb)

    TriggerServerEvent('oss_boats:BuyBoat', data)
    cb('ok')
end)

RegisterNetEvent('oss_boats:SetBoatName')
AddEventHandler('oss_boats:SetBoatName', function(data, rename)
    HideMenu()
    Wait(200)

    local boatName = ""
	Citizen.CreateThread(function()
		AddTextEntry('FMMC_MPM_NA', _U("nameBoat"))
		DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 30)
		while (UpdateOnscreenKeyboard() == 0) do
			DisableAllControlActions(0)
			Citizen.Wait(0)
		end
		if (GetOnscreenKeyboardResult()) then
            boatName = GetOnscreenKeyboardResult()
            if not rename then
                TriggerServerEvent('oss_boats:SaveNewBoat', data, boatName)
            else
                TriggerServerEvent('oss_boats:UpdateBoatName', data, boatName)
            end
		end
    end)
end)

-- Rename Owned Horse
RegisterNUICallback("RenameBoat", function(data, cb)
    local rename = true
    TriggerEvent('oss_boats:SetBoatName', data, rename)
    cb('ok')
end)

-- View Player Owned Boats
RegisterNUICallback("LoadMyBoat", function(data, cb)
    if ShowroomBoat_entity ~= nil then
        DeleteEntity(ShowroomBoat_entity)
        ShowroomBoat_entity = nil
    end

    local model = joaat(data.BoatModel)
    LoadBoatModel(model)

    if MyBoat_entity ~= nil then
        DeleteEntity(MyBoat_entity)
        MyBoat_entity = nil
    end

    if model ~= "keelboat" then
        SetCamFov(BoatCam, 50.0)
    else
        SetCamFov(BoatCam, 80.0)
    end

    local shopConfig = Config.boatShops[ShopId]
    MyBoat_entity = CreateVehicle(model, shopConfig.spawn.x, shopConfig.spawn.y, shopConfig.spawn.z, shopConfig.spawn.h, false, false)
    Citizen.InvokeNative(0x7263332501E07F52, MyBoat_entity, true) -- SetVehicleOnGroundProperly
    Citizen.InvokeNative(0x7D9EFB7AD6B19754, MyBoat_entity, true) -- FreezeEntityPosition
    SetModelAsNoLongerNeeded(model)
    cb('ok')
end)

-- Launch Player Owned Boats
RegisterNUICallback("LaunchBoat", function(data, cb)
    CloseMenu()
    if MyBoat ~= nil then
        DeleteEntity(MyBoat)
        MyBoat = nil
    end
    isAnchored = false

    MyBoatId = data.BoatId

    local model = joaat(data.BoatModel)
    LoadBoatModel(model)

    local boatConfig = Config.boatShops[ShopId]
    MyBoat = CreateVehicle(model, boatConfig.spawn.x, boatConfig.spawn.y, boatConfig.spawn.z, boatConfig.spawn.h, true, false)
    SetVehicleOnGroundProperly(MyBoat)
    SetModelAsNoLongerNeeded(model)
    SetEntityInvincible(MyBoat, 1)
    DoScreenFadeOut(500)
    Wait(500)
    SetPedIntoVehicle(PlayerPedId(), MyBoat, -1)
    Wait(500)
    DoScreenFadeIn(500)

    TriggerServerEvent('oss_boats:RegisterInventory', MyBoatId)

    local myBoatName = data.BoatName
    local boatBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1749618580, MyBoat) -- BlipAddForEntity
    SetBlipSprite(boatBlip, joaat("blip_canoe"), true)
    Citizen.InvokeNative(0x9CB1A1623062F402, boatBlip, myBoatName) -- SetBlipName
    VORPcore.NotifyRightTip(_U("boatMenuTip"),4000)
    cb('ok')
end)

-- Sell Player Owned Boats
RegisterNUICallback("SellBoat", function(data, cb)
    local boatId = tonumber(data.BoatId)
    local boatName = data.BoatName
    DeleteEntity(MyBoat_entity)
    HideMenu()
    TriggerServerEvent('oss_boats:SellBoat', boatId, boatName, ShopId)
    cb('ok')
end)

-- Close Main Menu
RegisterNUICallback("CloseMenu", function(data, cb)
    CloseMenu()
    cb('ok')
end)

function CloseMenu()
    HideMenu()

     if ShowroomBoat_entity ~= nil then
        DeleteEntity(ShowroomBoat_entity)
    end
    ShowroomBoat_entity = nil

    if MyBoat_entity ~= nil then
        DeleteEntity(MyBoat_entity)
    end
    MyBoat_entity = nil

    DestroyAllCams(true)
    DisplayRadar(true)
    InMenu = false
    ClearPedTasksImmediately(PlayerPedId())
end

function HideMenu()
    SendNUIMessage({ action = "hide" })
    SetNuiFocus(false, false)
end

function LoadBoatModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(100)
    end
end

-- Reopen Menu After Sell or Failed Purchase
RegisterNetEvent('oss_boats:BoatMenu')
AddEventHandler('oss_boats:BoatMenu', function()
    if ShowroomBoat_entity ~= nil then
        DeleteEntity(ShowroomBoat_entity)
        ShowroomBoat_entity = nil
    end
    TriggerServerEvent('oss_boats:GetMyBoats')
end)

-- Boat Actions
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if Citizen.InvokeNative(0x580417101DDB492F, 2, Config.optionKey) then -- IsControlJustPressed
            if MyBoat then
                local player = PlayerPedId()
                local pcoords = GetEntityCoords(player)
                local hcoords = GetEntityCoords(MyBoat)
                local invDist = #(pcoords - hcoords)
                if IsPedInAnyBoat(player) and invDist <= 1.0 then
                    BoatOptionsMenu()
                end
            end
        end
    end
end)

function BoatOptionsMenu()
    MenuData.CloseAll()
    InMenu = true
    local player = PlayerPedId()
    local elements = {
        {
            label = _U("anchorMenu"),
            value = "anchor",
            desc = _U("anchorAction")
        },
        {
            label = _U("inventoryMenu"),
            value = "inventory",
            desc = _U("inventoryAction")
        },
        {
            label = _U("returnMenu"),
            value = "return",
            desc = _U("returnAction")
        }
    }
    MenuData.Open('default', GetCurrentResourceName(), 'menuapi', {
        title    = _U("boatMenu"),
        subtext  = _U("boatSubMenu"),
        align    = "top-left",
        elements = elements,
    }, function(data, menu)
        if data.current.value == "anchor" then

            local playerBoat = GetVehiclePedIsIn(player, true)
            if not isAnchored then
                SetBoatAnchor(playerBoat, true)
                SetBoatFrozenWhenAnchored(playerBoat, true)
                isAnchored = true
                VORPcore.NotifyRightTip(_U("anchorDown"),4000)
            else
                SetBoatAnchor(playerBoat, false)
                isAnchored = false
                VORPcore.NotifyRightTip(_U("anchorUp"),4000)
            end

            menu.close()
            InMenu = false

        elseif data.current.value == "inventory" then

            TriggerServerEvent('oss_boats:OpenInventory', MyBoatId)

            menu.close()
            InMenu = false

        elseif data.current.value == "return" then

            TaskLeaveVehicle(player, MyBoat, 0)

            menu.close()
            InMenu = false
            Wait(15000)
            DeleteEntity(MyBoat)
            MyBoat = nil
        end
    end,
    function(data, menu)
        menu.close()
        InMenu = false
        ClearPedTasksImmediately(player)
        DisplayRadar(true)
    end)
end

-- Return Boat Using Prompt at Shop Location
function ReturnBoat(shopId)
    local player = PlayerPedId()
    local shopConfig = Config.boatShops[shopId]
    TaskLeaveVehicle(player, MyBoat, 0)
    DoScreenFadeOut(500)
    Wait(500)
    Citizen.InvokeNative(0x203BEFFDBE12E96A, player, shopConfig.player.x, shopConfig.player.y, shopConfig.player.z, shopConfig.player.h) -- SetEntityCoordsAndHeading
    Wait(500)
    DoScreenFadeIn(500)
    DeleteEntity(MyBoat)
    MyBoat = nil
end

-- Camera to View Boats
function CreateCamera()
    local shopConfig = Config.boatShops[ShopId]
    BoatCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(BoatCam, shopConfig.boatCam.x, shopConfig.boatCam.y, shopConfig.boatCam.z + 1.2 )
    SetCamActive(BoatCam, true)
    PointCamAtCoord(BoatCam, shopConfig.spawn.x, shopConfig.spawn.y, shopConfig.spawn.z)
    SetCamFov(BoatCam, 50.0)
    DoScreenFadeOut(500)
    Wait(500)
    DoScreenFadeIn(500)
    RenderScriptCams(true, false, 0, 0, 0)
end

-- Rotate Boats while Viewing
RegisterNUICallback("Rotate", function(data, cb)
    local direction = data.RotateBoat
    if direction == "left" then
        Rotation(20)
    elseif direction == "right" then
        Rotation(-20)
    end
    cb('ok')
end)

function Rotation(dir)
    if MyBoat_entity then
        local ownedRot = GetEntityHeading(MyBoat_entity) + dir
        SetEntityHeading(MyBoat_entity, ownedRot % 360)

    elseif ShowroomBoat_entity then
        local shopRot = GetEntityHeading(ShowroomBoat_entity) + dir
        SetEntityHeading(ShowroomBoat_entity, shopRot % 360)
    end
end

RegisterCommand("boatEnter", function(rawCommand)
    DoScreenFadeOut(500)
    Wait(500)
    SetPedIntoVehicle(PlayerPedId(), MyBoat, -1)
    Wait(500)
    DoScreenFadeIn(500)
end)

-- Prevents Boat from Sinking
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local player = PlayerPedId()
        if IsPedInAnyBoat(player) then
            SetPedResetFlag(player, 364, 1)
        end
    end
end)

-- Menu Prompts
function ShopOpen()
    local str = _U("shopPrompt")
    OpenShops = PromptRegisterBegin()
    PromptSetControlAction(OpenShops, Config.shopKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(OpenShops, str)
    PromptSetEnabled(OpenShops, 1)
    PromptSetVisible(OpenShops, 1)
    PromptSetStandardMode(OpenShops, 1)
    PromptSetGroup(OpenShops, ShopPrompt1)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, OpenShops, true) -- UiPromptSetUrgentPulsingEnabled
    PromptRegisterEnd(OpenShops)
end

function ShopClosed()
    local str = _U("shopPrompt")
    CloseShops = PromptRegisterBegin()
    PromptSetControlAction(CloseShops, Config.shopKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(CloseShops, str)
    PromptSetEnabled(CloseShops, 1)
    PromptSetVisible(CloseShops, 1)
    PromptSetStandardMode(CloseShops, 1)
    PromptSetGroup(CloseShops, ShopPrompt2)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, CloseShops, true) -- UiPromptSetUrgentPulsingEnabled
    PromptRegisterEnd(CloseShops)
end

function ReturnOpen()
    local str = _U("returnPrompt")
    OpenReturn = PromptRegisterBegin()
    PromptSetControlAction(OpenReturn, Config.returnKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(OpenReturn, str)
    PromptSetEnabled(OpenReturn, 1)
    PromptSetVisible(OpenReturn, 1)
    PromptSetStandardMode(OpenReturn, 1)
    PromptSetGroup(OpenReturn, ReturnPrompt1)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, OpenReturn, true) -- UiPromptSetUrgentPulsingEnabled
    PromptRegisterEnd(OpenReturn)
end

function ReturnClosed()
    local str = _U("returnPrompt")
    CloseReturn = PromptRegisterBegin()
    PromptSetControlAction(CloseReturn, Config.returnKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(CloseReturn, str)
    PromptSetEnabled(CloseReturn, 1)
    PromptSetVisible(CloseReturn, 1)
    PromptSetStandardMode(CloseReturn, 1)
    PromptSetGroup(CloseReturn, ReturnPrompt2)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, CloseReturn, true) -- UiPromptSetUrgentPulsingEnabled
    PromptRegisterEnd(CloseReturn)
end

-- Blips
function AddBlip(shopId)
    local shopConfig = Config.boatShops[shopId]
    if shopConfig.blipAllowed then
        shopConfig.BlipHandle = N_0x554d9d53f696d002(1664425300, shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z) -- BlipAddForCoords
        SetBlipSprite(shopConfig.BlipHandle, shopConfig.blipSprite, 1)
        SetBlipScale(shopConfig.BlipHandle, 0.2)
        Citizen.InvokeNative(0x9CB1A1623062F402, shopConfig.BlipHandle, shopConfig.blipName) -- SetBlipName
    end
end

-- NPCs
function SpawnNPC(shopId)
    local shopConfig = Config.boatShops[shopId]
    LoadModel(shopConfig.npcModel)
    if shopConfig.npcAllowed then
        local npc = CreatePed(shopConfig.npcModel, shopConfig.npc.x, shopConfig.npc.y, shopConfig.npc.z, shopConfig.npc.h, false, true, true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation
        SetEntityCanBeDamaged(npc, false)
        SetEntityInvincible(npc, true)
        Wait(500)
        FreezeEntityPosition(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        Config.boatShops[shopId].NPC = npc
    end
end

function LoadModel(npcModel)
    local model = joaat(npcModel)
    RequestModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(100)
    end
end

-- Check if Player has Job
function CheckJob(allowedJob, playerJob)
    for _, jobAllowed in pairs(allowedJob) do
        JobName = jobAllowed
        if JobName == playerJob then
            return true
        end
    end
    return false
end

RegisterNetEvent("oss_boats:sendPlayerJob")
AddEventHandler("oss_boats:sendPlayerJob", function(Job, grade)
    PlayerJob = Job
    JobGrade = grade
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if InMenu == true then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "hide" })
        MenuData.CloseAll()
    end
    ClearPedTasksImmediately(PlayerPedId())
    PromptDelete(OpenShops)
    PromptDelete(CloseShops)
    PromptDelete(OpenReturn)
    PromptDelete(CloseReturn)
    DestroyAllCams(true)
    DisplayRadar(true)

    if MyBoat then
        DeleteEntity(MyBoat)
        MyBoat = nil
    end

    for _, shopConfig in pairs(Config.boatShops) do
        if shopConfig.BlipHandle then
            RemoveBlip(shopConfig.BlipHandle)
        end
        if shopConfig.NPC then
            DeleteEntity(shopConfig.NPC)
            DeletePed(shopConfig.NPC)
            SetEntityAsNoLongerNeeded(shopConfig.NPC)
        end
    end
end)
