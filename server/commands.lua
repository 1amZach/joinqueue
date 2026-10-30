local function reply(src, text)
    if src == 0 then
        print(text)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'queue', text } })
    end
end

local function entryAt(src, position)
    local entry = Queue.list()[tonumber(position) or 0]
    if not entry then reply(src, 'Nobody at that position') end
    return entry
end

local actions = {}

function actions.list(src)
    local people = Queue.list()
    if #people == 0 then return reply(src, 'The queue is empty') end

    for i, entry in ipairs(people) do
        reply(src, ('%d. %s  [%s]  %s  %ds'):format(
            i, entry.name, entry.priority.label or 'Standard', entry.license, os.time() - entry.joined))
    end
end

function actions.pause(src, args)
    local reason = table.concat(args, ' ', 2)
    Queue.setPaused(reason ~= '' and reason or true)
    reply(src, 'Queue paused')
end

function actions.resume(src)
    Queue.setPaused(false)
    reply(src, 'Queue resumed')
end

function actions.skip(src, args)
    local entry = entryAt(src, args[2])
    if not entry then return end
    Queue.moveToFront(entry)
    reply(src, ('%s moved to the front'):format(entry.name))
end

function actions.remove(src, args)
    local entry = entryAt(src, args[2])
    if not entry then return end
    Queue.remove(entry, Config.messages.removed)
    reply(src, ('%s removed from the queue'):format(entry.name))
end

function actions.prio(src, args)
    local identifier, tier, minutes = args[2], args[3], tonumber(args[4])
    if not identifier or not tier then
        return reply(src, 'Usage: queue prio <identifier> <tier> [minutes]')
    end

    local ok, err = Priority.grant(identifier, tier, minutes)
    if not ok then return reply(src, err) end

    reply(src, ('%s now has %s%s'):format(identifier, tier, minutes and (' for %d minutes'):format(minutes) or ''))
end

function actions.unprio(src, args)
    if not args[2] then return reply(src, 'Usage: queue unprio <identifier>') end
    Priority.revoke(args[2])
    reply(src, ('Removed priority from %s'):format(args[2]))
end

RegisterCommand('queue', function(src, args)
    local action = actions[args[1] or 'list']
    if not action then
        return reply(src, 'queue list | pause [reason] | resume | skip <pos> | remove <pos> | prio <id> <tier> [minutes] | unprio <id>')
    end
    action(src, args)
end, true)
