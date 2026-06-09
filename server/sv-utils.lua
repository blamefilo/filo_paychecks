local playerHours = {}

local function CleanTable(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do
        res[CleanTable(k)] = CleanTable(v)
    end
    return res
end

local function LoadBIN(file)
    local binaryData = LoadResourceFile(cache.resource, file, -1)
    if not binaryData or binaryData == "" then return {} end

    local success, myData = pcall(msgpack.unpack, binaryData)
    if not success then
        print("^1[Error]^7 " .. file .. " was corrupted or incomplete. Starting with fresh table.")
        return {}
    end
    return myData or {}
end

local function SaveBIN(file, data)
    local cleanTable = CleanTable(data)
    local binaryBytes = msgpack.pack(cleanTable)
    SaveResourceFile(cache.resource, file, binaryBytes, #binaryBytes)
end

function SetPlayerMinutes(identifier, job, minutes)
    local playerData = playerHours[identifier] or {}
    playerData[job] = minutes

    playerHours[identifier] = playerData
end

function GetPlayerMinutes(identifier, job)
    local playerData = playerHours[identifier] or {}
    return playerData[job] or 0
end

playerHours = LoadBIN('data/playerHours.bin')
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then return end

    SaveBIN('data/playerHours.bin', playerHours)
end)