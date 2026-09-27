local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local WEBHOOK_URL = "https://discordapp.com/api/webhooks/1553082164952830113/oNihfynTKZZ6qIXQ0pChCKLu1i9M4N-8JgzN_0L-DY6P_XrXAPFIxB672HFwBC55dj7V"
local HUB_PLACE_ID = 15327728308
local PING_ROLE_ID = "1553082652268175391"
local ITENS_ALVO = {"barret50", "renellim4", "m79", "backpacktier4"}

-- ================================
-- Pause Config
-- ================================
local PAUSE_CONFIG = {
    KEYBIND = Enum.KeyCode.F6,

    barret50      = true,   -- if barret then pause
    renellim4     = true,   -- if renellim4 then pause
    m79           = false,  -- if m79 then pause
    backpacktier4 = true,   -- if backpacktier4 then pause

    ChineseZombie  = 0,     -- min. Quantity to pause (0 = dont pause)
    TacticalZombie = 0,     -- min. Quantity to pause (0 = dont pause)
}
-- ================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local paused = false
local pauseConnection = nil

local function sendToDiscord(msg, ping)
    local req = syn and syn.request or http_request or request
    if not req then return end
    local content = ping and ("<@&" .. PING_ROLE_ID .. "> " .. msg) or msg
    pcall(function()
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = content})
        })
    end)
end

local function setupKeybind(onResume)
    if pauseConnection then
        pauseConnection:Disconnect()
        pauseConnection = nil
    end
    pauseConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == PAUSE_CONFIG.KEYBIND and paused then
            paused = false
            pauseConnection:Disconnect()
            pauseConnection = nil
            onResume()
        end
    end)
end

local function waitForResume(onResume)
    paused = true
    setupKeybind(onResume)
end

task.wait(5)

local found = {}
local pinged = {}
local shouldPause = false

local chineseCount = 0
local tacticalCount = 0

local function scanPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == Players.LocalPlayer then continue end

        local inv = player:WaitForChild("GunInventory", 5)
        if inv then
            for _, obj in ipairs(inv:GetChildren()) do
                if obj:IsA("ObjectValue") and obj.Value then
                    local nome = obj.Value.Name
                    for _, alvo in ipairs(ITENS_ALVO) do
                        if nome and nome:lower():find(alvo:lower()) then
                            local key = player.Name .. nome
                            if not pinged[key] then
                                pinged[key] = true
                                local mag = obj:FindFirstChild("BulletsInMagazine") and obj.BulletsInMagazine.Value or 0
                                table.insert(found, string.format("%s | %s | %d balas", player.Name, nome, mag))
                                sendToDiscord("Found: " .. player.Name .. " | " .. nome, true)

                                if PAUSE_CONFIG[alvo] then
                                    shouldPause = true
                                end
                            end
                        end
                    end
                end
            end
        end

        local bp = player:GetAttribute("EquipmentBackpack")
        if bp and tostring(bp):lower():find("backpacktier4") then
            local key = player.Name .. "tier4"
            if not pinged[key] then
                pinged[key] = true
                table.insert(found, string.format("%s | BackpackTier4 | N/A", player.Name))
                sendToDiscord("Tier4: " .. player.Name, true)

                if PAUSE_CONFIG["backpacktier4"] then
                    shouldPause = true
                end
            end
        end
    end
end

local function scanZombies()
    pcall(function()
        local EmberClient = require(game:GetService("ReplicatedFirst")
            :WaitForChild("EmberClientLibrary")
            :WaitForChild("EmberClient")
            :WaitForChild("EmberClient"))
        local NPCSimulatorService = EmberClient:GetService("NPCSimulatorService")
        for _, Zombie in NPCSimulatorService.NPCs do
            for _, Item in Zombie.Equipment do
                local ItemClass = Item.ClassName
                local Skin = Item.SkinOverride
                if ItemClass:find("Altyn") then
                    local key = "chinese" .. tostring(Zombie)
                    if not pinged[key] then
                        pinged[key] = true
                        chineseCount += 1
                        sendToDiscord("Chinese zombie: " .. ItemClass:gsub(".item", ""), true)
                        if PAUSE_CONFIG.ChineseZombie > 0 and chineseCount >= PAUSE_CONFIG.ChineseZombie then
                            shouldPause = true
                        end
                    end
                elseif Skin and Skin:find("Beret") then
                    local key = "tactical" .. tostring(Zombie)
                    if not pinged[key] then
                        pinged[key] = true
                        tacticalCount += 1
                        sendToDiscord("Tactical zombie: " .. Skin, true)
                        if PAUSE_CONFIG.TacticalZombie > 0 and tacticalCount >= PAUSE_CONFIG.TacticalZombie then
                            shouldPause = true
                        end
                    end
                end
            end
        end
    end)
end

for i = 1, 3 do
    scanPlayers()
    scanZombies()
    task.wait(4)
end

if #found > 0 then
    sendToDiscord("Total: " .. #found, false)
end

if shouldPause then
    local function continueLoop()
        task.wait(2)
        local qt = queue_on_teleport or queueteleport or (syn and syn.queue_on_teleport)
        if qt then
            qt([[loadstring(game:HttpGet("https://raw.githubusercontent.com/SEUREPOSITORIOAQUI/hub.lua"))()]])
        end
        TeleportService:Teleport(HUB_PLACE_ID)
    end
    waitForResume(continueLoop)
else
    task.wait(2)
    local qt = queue_on_teleport or queueteleport or (syn and syn.queue_on_teleport)
    if qt then
        qt([[loadstring(game:HttpGet("https://raw.githubusercontent.com/SEUREPOSITORIOAQUI/hub.lua"))()]])
    end
    TeleportService:Teleport(HUB_PLACE_ID)
end
