local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local Library = nil
pcall(function()
    Library = require(game.ReplicatedStorage:WaitForChild("Library", 15))
end)

local WEBHOOK_URL = "https://discordapp.com/api/webhooks/1553082164952830113/oNihfynTKZZ6qIXQ0pChCKLu1i9M4N-8JgzN_0L-DY6P_XrXAPFIxB672HFwBC55dj7V"
local HUB_PLACE_ID = 15327728308
local PING_ROLE_ID = "1553082652268175391"

local SERVERS = {
    "Abyss","Aftermath","Alpha","Anarchy","Armageddon","Banshee","Blight","Bravo",
    "Carnage","Cataclysm","Charlie","Chaos","Delta","Despair","Doom","Dread",
    "Echo","Eclipse","Eerie","Fallout","Foxtrot","Frenzy","Gloom","Golf",
    "Grave","Grim","Harrow","Havoc","Hotel","Ignition","India","Inferno",
    "Jagged","Judgement","Juliett","Kilo","Kraken","Krypt","Lament","Lima",
    "Limbo","Malice","Marrow","Mike","Morbid","Necrosis","November","Null",
    "Oblivion","Obsidian","Oscar","Papa","Pestilence","Plague","Quarantine",
    "Quandary","Quebec","Ragnarok","Ravage","Reaper","Revenant","Romeo","Ruin",
    "Scourge","Sentinel","Shade","Sierra","Tango","Tempest","Torment","Ulcer","Unholy","Uniform"
}

local FILENAME = "scanned_servers.txt"

local function loadScanned()
    if isfile and isfile(FILENAME) then
        local data = readfile(FILENAME)
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(data)
        end)
        if success and type(decoded) == "table" then
            return decoded
        end
    end
    return {}
end

local function saveScanned(data)
    if writefile then
        local success, encoded = pcall(function()
            return HttpService:JSONEncode(data)
        end)
        if success then
            writefile(FILENAME, encoded)
        end
    end
end

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

local scanned = loadScanned()
local currentIndex = 1
local isProcessing = false
local hasStarted = false

local function joinNextServer()
    if isProcessing then return end
    isProcessing = true

    if currentIndex > #SERVERS then
        currentIndex = 1
        scanned = {}
        saveScanned(scanned)
        isProcessing = false
        task.wait(5)
        return joinNextServer()
    end

    local serverName = SERVERS[currentIndex]
    currentIndex += 1

    if scanned[serverName] then
        isProcessing = false
        return joinNextServer()
    end

    scanned[serverName] = true
    saveScanned(scanned)

    sendToDiscord("Server: " .. serverName, false)

    if Library and Library.Network then
        Library.Network:Fire("Player.JoinServer", serverName)
    end

    task.wait(1)
    isProcessing = false
end

TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
    if errorMessage and string.find(string.lower(errorMessage), "full") then
        task.wait(1)
        isProcessing = false
        joinNextServer()
    end
end)

local qt = queue_on_teleport or queueteleport or (syn and syn.queue_on_teleport)
if qt then
    qt([[loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_REPOSITORIO_AQUI/game.lua"))()]])
end

RunService.Heartbeat:Connect(function()
    if game.PlaceId == HUB_PLACE_ID and not hasStarted then
        hasStarted = true
        task.wait(2)
        joinNextServer()
    end
end)
