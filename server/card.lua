Card = {}

local function title()
    if Config.card.title then return Config.card.title end
    local name = GetConvar('sv_projectName', '')
    if name == '' then name = GetConvar('sv_hostname', 'FiveM') end
    -- strip colour codes like ^1
    return (name:gsub('%^%d', ''))
end

local function clock(seconds)
    return ('%d:%02d'):format(seconds // 60, seconds % 60)
end

local function wait(seconds)
    if not seconds then return 'Calculating' end
    if seconds < 60 then return 'Under a minute' end
    return ('~%d min'):format(math.ceil(seconds / 60))
end

local function bar(progress, width)
    local filled = math.floor(progress * width + 0.5)
    return ('▰'):rep(filled) .. ('▱'):rep(width - filled)
end

local function stat(label, value)
    return {
        type = 'Column',
        width = 'stretch',
        items = {
            { type = 'TextBlock', text = label, size = 'Small', isSubtle = true, horizontalAlignment = 'Center' },
            { type = 'TextBlock', text = value, size = 'Medium', weight = 'Bolder', horizontalAlignment = 'Center' },
        },
    }
end

-- info: { position, total, eta, status, now }
function Card.build(entry, info)
    local body = {}

    if Config.card.image then
        body[#body + 1] = { type = 'Image', url = Config.card.image, size = 'Stretch' }
    end

    body[#body + 1] = { type = 'TextBlock', text = title(), size = 'Large', weight = 'Bolder', horizontalAlignment = 'Center', wrap = true }

    if info.status then
        body[#body + 1] = { type = 'TextBlock', text = info.status, color = 'Warning', horizontalAlignment = 'Center', wrap = true }
    end

    body[#body + 1] = {
        type = 'ColumnSet',
        columns = {
            stat('POSITION', ('%d / %d'):format(info.position, info.total)),
            stat('EST. WAIT', wait(info.eta)),
            stat('PRIORITY', entry.priority.label or 'Standard'),
            stat('IN QUEUE', clock(info.now - entry.joined)),
        },
    }

    local start = math.max(entry.startPos or info.position, 1)
    local progress = start > 1 and (start - info.position) / (start - 1) or 0
    body[#body + 1] = { type = 'TextBlock', text = bar(progress, 24), color = 'Accent', horizontalAlignment = 'Center' }

    local tips = Config.card.tips
    if tips and #tips > 0 then
        body[#body + 1] = {
            type = 'TextBlock',
            text = tips[(info.now // 8) % #tips + 1],
            isSubtle = true,
            wrap = true,
            horizontalAlignment = 'Center',
        }
    end

    local actions = {}
    if Config.card.discord then
        actions[#actions + 1] = { type = 'Action.OpenUrl', title = 'Discord', url = Config.card.discord }
    end
    actions[#actions + 1] = { type = 'Action.Submit', title = 'Leave queue', data = { action = 'leave' } }

    return {
        type = 'AdaptiveCard',
        version = '1.3',
        ['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
        body = body,
        actions = actions,
    }
end
