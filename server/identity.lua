Identity = {}

-- { license = 'license:...', discord = 'discord:...', ... }, first of each kind
function Identity.get(src)
    local ids = {}

    for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
        local kind = id:match('^(%w+):')
        if kind and not ids[kind] then ids[kind] = id end
    end

    return ids
end

local cache = {}

local function get(url, token)
    local p = promise.new()
    local finished = false

    PerformHttpRequest(url, function(status, body)
        if finished then return end
        finished = true
        p:resolve({ status = status, body = body })
    end, 'GET', '', { Authorization = 'Bot ' .. token })

    SetTimeout(5000, function()
        if finished then return end
        finished = true
        p:resolve({ status = 0 })
    end)

    return Citizen.Await(p)
end

-- Role ids for a member, false if they aren't in the guild,
-- nil when Discord isn't set up or didn't answer.
function Identity.discordRoles(discordId)
    local token = GetConvar('joinqueue_discord_token', '')
    if not Config.discord.enabled or token == '' or not discordId then return nil end

    local id = discordId:sub(9)
    local hit = cache[id]
    if hit and hit.expires > os.time() then return hit.roles end

    local res = get(('https://discord.com/api/v10/guilds/%s/members/%s'):format(Config.discord.guild, id), token)
    local roles

    if res.status == 200 then
        local ok, member = pcall(json.decode, res.body)
        roles = ok and type(member) == 'table' and member.roles or {}
    elseif res.status == 404 then
        roles = false
    else
        print(('[joinqueue] Discord lookup failed (%s), check the bot token and guild id'):format(res.status))
        return nil
    end

    cache[id] = { roles = roles, expires = os.time() + 300 }
    return roles
end
