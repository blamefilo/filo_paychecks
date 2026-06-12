Bridge = exports.community_bridge:Bridge()

for key, value in pairs(Bridge) do
    if key ~= "Entity" then
        load(key .. " = ...") (value)
    end
end

function DebugPrint(...)
    if not Config.Debug then return end
    print('[Filo Paycheck] ' .. table.concat({...}, ' '))
end