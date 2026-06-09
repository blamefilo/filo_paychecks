local cachedPlayers = {}
local frameworkJobs = Framework.GetFrameworkJobs()

local function cachePlayerJobs(source)
    local identifier = Framework.GetPlayerIdentifier(source)
    local result = MySQL.single.await('SELECT * FROM filo_paychecks USE INDEX (idx_citizenid) WHERE citizenid = ?', { identifier })

    if result then
        cachedPlayers[identifier] = {
            jobs = json.decode(result.jobs),
            paychecks = json.decode(result.paychecks)
        }
    else
        local playerJob = Framework.GetPlayerJobData(source)
        local defaultPaycheck = frameworkJobs[playerJob.jobName].grades[playerJob.gradeRank].payment or 0
        local jobData = {
            [playerJob.jobName] = {
                jobLabel = frameworkJobs[playerJob.jobName].label,
                grade = playerJob.gradeRank,
                gradeLabel = playerJob.gradeLabel,
                paycheck = defaultPaycheck,
                offDutyPay = frameworkJobs[playerJob.jobName].offDutyPay or false
            }
        }
        MySQL.insert.await('INSERT INTO filo_paychecks (citizenid, jobs, paychecks) VALUES (?, ?, ?)', { identifier, json.encode(jobData), json.encode({}) })
        cachedPlayers[identifier] = {
            jobs = jobData,
            paychecks = {}
        }
    end
end

function AddPaycheck(identifier, job, amount)
    if not cachedPlayers[identifier] then return end
    if not cachedPlayers[identifier].paychecks[job] then
        cachedPlayers[identifier].paychecks[job] = 0
    end

    DebugPrint("Adding paycheck for " .. job .. " for " .. amount .. " to " .. identifier)
    cachedPlayers[identifier].paychecks[job] += amount

    if Config.NotifyOnPaycheck then
        local source = Framework.GetPlayerSource(identifier)
        if not source then return end

        local jobLabel = cachedPlayers[identifier].jobs[job].jobLabel
        if Config.NotifyType == "framework" then
            Notify.SendNotification(source, "Paycheck Received", "You have received a paycheck of $" .. amount .. " for your work at " .. jobLabel, "info")
        elseif Config.NotifyType == "lb-phone" then
            Phone.SendEmail(source,
                job .. "paychecks@filo.com", -- sender
                "Payroll Notification: " .. jobLabel, -- subject
                "You have received a paycheck of $" .. amount .. " for your work at " .. jobLabel -- message
            )
        end
    end
end

CreateThread(function()
    for _, source in pairs(Framework.GetPlayers()) do
        local identifier = Framework.GetPlayerIdentifier(source)
        if not cachedPlayers[identifier] then cachePlayerJobs(source) end
    end

    while true do
        Wait(60000)

        for _, source in pairs(Framework.GetPlayers()) do
            local identifier = Framework.GetPlayerIdentifier(source)
            if not cachedPlayers[identifier] then cachePlayerJobs(source) end

            local playerJob = Framework.GetPlayerJobData(source)
            if playerJob and playerJob.jobName == 'unemployed' then goto skip end

            local playerMinutes = GetPlayerMinutes(identifier, playerJob.jobName) or 0
            playerMinutes += 1

            if playerMinutes % Config.PaycheckInterval ~= 0 then
                SetPlayerMinutes(identifier, playerJob.jobName, playerMinutes)
                goto skip
            else
                SetPlayerMinutes(identifier, playerJob.jobName, 0)
            end

            local jobData = cachedPlayers[identifier].jobs[playerJob.jobName]

            if not jobData then
                local defaultPaycheck = frameworkJobs[playerJob.jobName].grades[playerJob.gradeRank].payment or 0
                cachedPlayers[identifier].jobs[playerJob.jobName] = {
                    jobLabel = frameworkJobs[playerJob.jobName].label,
                    grade = playerJob.gradeRank,
                    gradeLabel = playerJob.gradeLabel,
                    paycheck = defaultPaycheck,
                    offDutyPay = frameworkJobs[playerJob.jobName].offDutyPay or false
                }
                jobData = cachedPlayers[identifier].jobs[playerJob.jobName]
            end
            if jobData.paycheck < 1 then
                DebugPrint("Paycheck amount is less than 1 for " .. playerJob.jobName .. " for " .. identifier)
                goto skip
            end
            if not jobData.offDutyPay and not playerJob.onDuty then
                DebugPrint("Off duty pay is disabled and player is not on duty for " .. playerJob.jobName .. " for " .. identifier)
                goto skip
            end

            AddPaycheck(identifier, playerJob.jobName, jobData.paycheck)
            ::skip::
        end
    end
end)

lib.callback.register("filo_paychecks:server:getAllPaychecks", function(source, identifier)
    local identifier = identifier or Framework.GetPlayerIdentifier(source)
    if not cachedPlayers[identifier] then return nil end

    return cachedPlayers[identifier].jobs, cachedPlayers[identifier].paychecks
end)

lib.callback.register("filo_paychecks:server:getPaycheckData", function(source, job, identifier)
    local identifier = identifier or Framework.GetPlayerIdentifier(source)
    if not cachedPlayers[identifier] then return nil end

    return cachedPlayers[identifier].jobs[job]
end)

lib.callback.register("filo_paychecks:server:updatePaycheckData", function(source, job, identifier, paycheck, offDutyPay)
    local identifier = identifier or Framework.GetPlayerIdentifier(source)
    if not cachedPlayers[identifier] then return false end

    cachedPlayers[identifier].jobs[job].paycheck = paycheck
    cachedPlayers[identifier].jobs[job].offDutyPay = offDutyPay

    return true
end)

lib.callback.register("filo_paychecks:server:claimPaycheck", function(source, job)
    local identifier = Framework.GetPlayerIdentifier(source)
    if not cachedPlayers[identifier] then return false end

    local paycheck = cachedPlayers[identifier].paychecks[job]
    if not paycheck or paycheck < 1 then return false end

    if not Framework.AddAccountBalance(source, "cash", paycheck) then
        DebugPrint("Failed to add paycheck to player " .. identifier)
        return false
    end

    DebugPrint("Added paycheck to player " .. identifier .. " for " .. job)
    Notify.SendNotification(source, 'Paycheck Claimed', 'You have claimed your paycheck of $' .. paycheck .. '.', 'success')

    cachedPlayers[identifier].paychecks[job] = 0
    return true
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= cache.resource then return end

    for identifier, data in pairs(cachedPlayers) do
        MySQL.update.await('UPDATE filo_paychecks SET jobs = ?, paychecks = ? WHERE citizenid = ?', { json.encode(data.jobs), json.encode(data.paychecks), identifier })
    end
end)