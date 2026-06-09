local entities = {}
local points = {}

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(1000) end

    local function showPaycheckMenu()
        local options = {}
        local jobs, paychecks = GetAllPaychecks()

        for job, data in pairs(jobs) do
            if job == 'unemployed' then goto continue end

            options[#options+1] = {
                title = data.jobLabel,
                description = ('Paycheck: **%s%s%s** \nClick to claim your paycheck for this job.'):format(Config.CurrencyPrefix, paychecks[job], Config.CurrencySuffix),
                arrow = paychecks[job] > 0,
                readOnly = paychecks[job] == 0,
                onSelect = function()
                    lib.callback.await('filo_paychecks:server:claimPaycheck', nil, job)
                end
            }
            ::continue::
        end

        lib.registerContext({
            id = 'filo_paychecks_menu',
            title = 'Paycheck',
            options = options
        })
        lib.showContext('filo_paychecks_menu')
    end

    local function createInteractionPoint(coords)
        if Config.InteractionType == 'target' then
            exports.ox_target:addSphereZone({
                coords = coords,
                radius = 0.5,
                debug = true,
                options = {
                    {
                        name = 'filo_paychecks:open',
                        icon = 'fas fa-money-check',
                        label = 'Paycheck',
                        distance = 2.5,
                        onSelect = showPaycheckMenu
                    }
                }
            })
        elseif Config.InteractionType == 'textui' then
            local point = lib.points.new({
                coords = coords,
                distance = 5.0,
                nearby = function(self)
                    if self.currentDistance < 2.5 then
                        lib.showTextUI('[E] Open Paycheck')
                        if IsControlJustReleased(2, 38) then
                            showPaycheckMenu()
                        end
                    else
                        lib.hideTextUI()
                    end
                end
            })
            points[#points+1] = point
        end
    end

    for _, v in pairs(Config.Locations) do
        if v.pedModel then
            local model = lib.requestModel(v.pedModel)

            local ped = CreatePed(4, model, v.coords.x, v.coords.y, v.coords.z, v.coords.w, false, true)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityCanBeDamagedByRelationshipGroup(ped, false, `PLAYER`)
            SetPedCanBeTargettedByPlayer(ped, cache.playerId, false)
            entities[#entities+1] = ped
        elseif v.objModel then
            local model = lib.requestModel(v.objModel)
            local obj = CreateObject(model, v.coords.x, v.coords.y, v.coords.z, false, false, false)
            SetEntityHeading(obj, v.coords.w)
            FreezeEntityPosition(obj, true)
            entities[#entities+1] = obj
        end

        createInteractionPoint(v.coords)
    end
end)

function GetAllPaychecks(identifier)
    return lib.callback.await('filo_paychecks:server:getAllPaychecks', false, identifier)
end

function GetPaycheckData(job, identifier)
    return lib.callback.await('filo_paychecks:server:getPaycheckData', false, job, identifier)
end

function UpdatePaycheckData(job, identifier, paycheck, offDutyPay)
    return lib.callback.await('filo_paychecks:server:updatePaycheckData', false, job, identifier, paycheck, offDutyPay)
end

exports('GetAllPaychecks', GetAllPaychecks)
exports('GetPaycheckData', GetPaycheckData)
exports('UpdatePaycheckData', UpdatePaycheckData)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then return end
    for _, v in pairs(entities) do
        DeleteEntity(v)
    end

    for _, v in pairs(points) do
        v:remove()
    end
end)