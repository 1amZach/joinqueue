Queue = {}

local list = {} -- people waiting, kept sorted
local connecting = {} -- license -> when they were let in, until they finish loading
local admissions = {} -- recent admit times, used for the wait estimate
local paused = false -- false or a reason
local readyAt = os.time() + Config.joinDelay
local seq = 0

local baseHostname

local function sort()
    table.sort(list, function(a, b)
        if a.priority.points ~= b.priority.points then
            return a.priority.points > b.priority.points
        end
        return a.seq < b.seq
    end)
end

local function find(license)
    for i, entry in ipairs(list) do
        if entry.license == license then return entry, i end
    end
end

-- people actually waiting, skipping anyone whose game closed
local function waiting()
    local out = {}
    for _, entry in ipairs(list) do
        if not entry.away then out[#out + 1] = entry end
    end
    return out
end

local function occupied()
    local count = #GetPlayers()
    for _ in pairs(connecting) do count = count + 1 end
    return count
end

local function finish(entry, message)
    if entry.deferrals then
        -- the client may already be gone, which makes done() throw
        pcall(entry.deferrals.done, message)
        entry.deferrals = nil
    end
end

local function eta(position, now)
    -- forget admissions older than half an hour, they say nothing about the current pace
    while admissions[1] and now - admissions[1] > 1800 do
        table.remove(admissions, 1)
    end

    local n = #admissions
    if n < 2 then return nil end

    local span = admissions[n] - admissions[1]
    if span <= 0 then return nil end

    return math.ceil(position / ((n - 1) / span))
end

function Queue.join(src, ids, name, priority, deferrals)
    local entry = find(ids.license)

    -- same person again, usually after their game closed: keep their place
    if entry then
        finish(entry)
        entry.src, entry.name, entry.priority, entry.deferrals = src, name, priority, deferrals
        entry.away = nil
        sort()
        return entry
    end

    seq = seq + 1
    entry = {
        src = src,
        license = ids.license,
        name = name,
        priority = priority,
        deferrals = deferrals,
        joined = os.time(),
        seq = seq,
    }

    list[#list + 1] = entry
    sort()
    return entry
end

function Queue.remove(entry, message)
    local _, i = find(entry.license)
    if i then table.remove(list, i) end
    finish(entry, message)
end

function Queue.admit(entry, now)
    local _, i = find(entry.license)
    if i then table.remove(list, i) end

    connecting[entry.license] = now or os.time()
    Priority.useGrace(entry.license)

    admissions[#admissions + 1] = now or os.time()
    if #admissions > 20 then table.remove(admissions, 1) end

    finish(entry)
end

function Queue.loaded(license)
    connecting[license] = nil
end

function Queue.setPaused(reason)
    paused = reason or false
end

function Queue.isPaused()
    return paused
end

-- position counts only people who are still here
function Queue.list()
    return waiting()
end

function Queue.moveToFront(entry)
    local first = list[1]
    if first and first ~= entry then
        entry.seq = first.seq - 1
        entry.priority = { points = math.max(entry.priority.points, first.priority.points), label = entry.priority.label, tier = entry.priority.tier }
    end
    sort()
end

local function updateHostname(count)
    if not Config.hostnameCount then return end
    baseHostname = baseHostname or GetConvar('sv_hostname', '')
    SetConvar('sv_hostname', count > 0 and ('[%d] %s'):format(count, baseHostname) or baseHostname)
end

function Queue.restoreHostname()
    if baseHostname then SetConvar('sv_hostname', baseHostname) end
end

function Queue.tick(now)
    now = now or os.time()

    for i = #list, 1, -1 do
        local entry = list[i]

        if not entry.away then
            local gone = not GetPlayerEndpoint(entry.src)
                or (GetPlayerLastMsg(entry.src) or 0) > Config.queueTimeout * 1000
            if gone then
                entry.away = now
                entry.deferrals = nil
            end
        end

        if entry.away and now - entry.away > Config.holdSpot then
            table.remove(list, i)
        end
    end

    for license, since in pairs(connecting) do
        if now - since > Config.connectTimeout then connecting[license] = nil end
    end

    sort()

    local status
    if paused then
        status = paused == true and Config.messages.paused or ('%s: %s'):format(Config.messages.paused, paused)
    elseif now < readyAt then
        status = Config.messages.starting
    else
        local free = GetConvarInt('sv_maxclients', 48) - occupied()

        for _, entry in ipairs(waiting()) do
            if free <= 0 then break end
            -- reserved slots are kept for priority players
            if entry.priority.points <= 0 and free <= Config.reservedSlots then break end

            Queue.admit(entry, now)
            free = free - 1
        end
    end

    local people = waiting()
    for position, entry in ipairs(people) do
        entry.startPos = math.max(entry.startPos or 0, position)

        if entry.deferrals then
            local card = Card.build(entry, { position = position, total = #people, eta = eta(position, now), status = status, now = now })
            local ok = pcall(entry.deferrals.presentCard, card, function(data)
                if type(data) == 'table' and data.action == 'leave' then
                    Queue.remove(entry, Config.messages.left)
                end
            end)
            if not ok then entry.deferrals = nil end
        end
    end

    updateHostname(#people)
end
