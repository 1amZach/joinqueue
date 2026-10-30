local messages = Config.messages

AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.update(messages.checking)

    local ids = Identity.get(src)

    if not ids.license then
        return deferrals.done(messages.noLicense)
    end

    if (Config.requireDiscord or Config.discord.requireMember) and not ids.discord then
        return deferrals.done(messages.needDiscord)
    end

    local priority, roles = Priority.resolve(src, ids)

    if Config.discord.requireMember and roles == false then
        return deferrals.done(messages.notMember)
    end

    if Config.whitelistOnly and priority.points <= 0 then
        return deferrals.done(messages.whitelist)
    end

    Queue.join(src, ids, name, priority, deferrals)
end)

-- fires once the player has finished loading in
AddEventHandler('playerJoining', function()
    local ids = Identity.get(source)
    if ids.license then Queue.loaded(ids.license) end
end)

AddEventHandler('playerDropped', function()
    local ids = Identity.get(source)
    if not ids.license then return end

    Queue.loaded(ids.license)
    Priority.addGrace(ids.license)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then Queue.restoreHostname() end
end)

CreateThread(function()
    while true do
        Queue.tick()
        Wait(1000)
    end
end)

exports('addPriority', function(identifier, tier, minutes)
    return Priority.grant(identifier, tier, minutes)
end)

exports('removePriority', function(identifier)
    Priority.revoke(identifier)
end)

exports('getQueue', function()
    local out = {}
    for i, entry in ipairs(Queue.list()) do
        out[i] = { position = i, name = entry.name, license = entry.license, priority = entry.priority.label, joined = entry.joined }
    end
    return out
end)

exports('setPaused', function(state, reason)
    Queue.setPaused(state and (reason or true) or false)
end)
