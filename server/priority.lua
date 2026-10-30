Priority = {}

local PREFIX = 'prio:'
local granted = {} -- identifier -> { tier, expires } from exports and commands
local grace = {} -- license -> unix time it runs out

do
    local handle = StartFindKvp(PREFIX)
    local key = FindKvp(handle)

    while key do
        local ok, entry = pcall(json.decode, GetResourceKvpString(key) or '')
        if ok and type(entry) == 'table' then
            granted[key:sub(#PREFIX + 1)] = entry
        end
        key = FindKvp(handle)
    end

    EndFindKvp(handle)
end

function Priority.grant(identifier, tier, minutes)
    if not Config.tiers[tier] then
        return false, ('no tier called "%s"'):format(tier)
    end

    local entry = { tier = tier, expires = minutes and os.time() + math.floor(minutes * 60) or nil }
    granted[identifier] = entry
    SetResourceKvp(PREFIX .. identifier, json.encode(entry))
    return true
end

function Priority.revoke(identifier)
    granted[identifier] = nil
    DeleteResourceKvp(PREFIX .. identifier)
end

function Priority.addGrace(license)
    if Config.grace.enabled and license then
        grace[license] = os.time() + Config.grace.minutes * 60
    end
end

function Priority.useGrace(license)
    grace[license] = nil
end

-- Every source is checked and the best tier wins.
-- Also returns the Discord roles so main.lua doesn't have to look them up twice.
function Priority.resolve(src, ids)
    local now = os.time()
    local best = { points = 0 }

    local function consider(name)
        local tier = name and Config.tiers[name]
        if tier and tier.points > best.points then
            best = { points = tier.points, label = tier.label, tier = name }
        end
    end

    for _, id in pairs(ids) do
        consider(Config.priority[id])

        local entry = granted[id]
        if entry then
            if entry.expires and entry.expires <= now then
                Priority.revoke(id)
            else
                consider(entry.tier)
            end
        end
    end

    for name in pairs(Config.tiers) do
        if IsPlayerAceAllowed(src, 'joinqueue.' .. name) then consider(name) end
    end

    local roles = Identity.discordRoles(ids.discord)
    if roles then
        for _, role in ipairs(roles) do consider(Config.discord.roles[role]) end
    end

    local until_ = ids.license and grace[ids.license]
    if until_ then
        if until_ <= now then
            grace[ids.license] = nil
        elseif Config.grace.points > best.points then
            best = { points = Config.grace.points, label = Config.grace.label, grace = true }
        end
    end

    return best, roles
end

function Priority.list()
    return granted
end
