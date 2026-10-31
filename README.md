# joinqueue

A connection queue for full servers. Instead of a line of text, players get a live card on the connecting screen with their position, an estimated wait, their priority, how long they've been waiting and a progress bar.

No dependencies, server side only.

## Features

- Queue card with position, estimated wait, priority, time in queue, progress bar and rotating tips
- Discord and "Leave queue" buttons on the card
- Priority tiers from the config, aces, Discord roles, or an export/command (permanent or timed)
- Crash grace: anyone who drops gets a few minutes of priority to get back in
- Your place is held for 2 minutes if your game closes while you wait
- Reserved slots that only priority players can use
- Pause the queue with a reason, e.g. during maintenance
- Whitelist-only mode, required Discord, required Discord membership
- Optional `[count]` in front of the server name
- A short join delay after a restart so the rest of the server can finish starting

The wait estimate comes from how fast people have actually been getting in over the last half hour, so it settles after a few joins.

## Install

1. Drop `joinqueue` into your resources.
2. In `server.cfg`, start it near the top and stop the built-in hardcap, which would otherwise kick people before the queue sees them:

```
stop hardcap
ensure joinqueue
```

3. Let admins use the commands:

```
add_ace group.admin command.queue allow
```

## Priority

Every source is checked and the highest tier wins. Tiers live in `Config.tiers`:

```lua
Config.tiers = {
    staff = { points = 100, label = 'Staff' },
    vip = { points = 50, label = 'VIP' },
}
```

**Config list**, any identifier:

```lua
Config.priority = {
    ['license:0123456789abcdef'] = 'staff',
}
```

**Aces**, named `joinqueue.<tier>`:

```
add_ace group.admin joinqueue.staff allow
add_principal identifier.discord:123456789012345678 group.admin
```

**Discord roles.** Make a bot, invite it to your guild and turn on the Server Members intent. Put the token in `server.cfg` so it never ends up in your files:

```
set joinqueue_discord_token "your bot token"
```

```lua
Config.discord = {
    enabled = true,
    guild = '123456789012345678',
    roles = {
        ['234567890123456789'] = 'vip',
    },
    requireMember = false,
}
```

Lookups are cached for 5 minutes. If Discord doesn't answer, the player is let into the queue without role priority rather than stuck.

**Granted priority** from the command or another resource, saved across restarts. Leave out the minutes to make it permanent.

```lua
exports.joinqueue:addPriority('license:0123456789abcdef', 'vip', 60 * 24 * 30) -- 30 days
exports.joinqueue:removePriority('license:0123456789abcdef')
```

## Commands

All under `queue`, needs `command.queue`. Works from the server console too.

| Command | |
|---|---|
| `queue list` | Everyone waiting, in order |
| `queue pause [reason]` | Stop letting people in, the reason shows on the card |
| `queue resume` | Start again |
| `queue skip <position>` | Move someone to the front |
| `queue remove <position>` | Take someone out of the queue |
| `queue prio <identifier> <tier> [minutes]` | Give priority |
| `queue unprio <identifier>` | Take it away |

## Exports

```lua
exports.joinqueue:addPriority(identifier, tier, minutes)
exports.joinqueue:removePriority(identifier)
exports.joinqueue:getQueue() -- { { position, name, license, priority, joined }, ... }
exports.joinqueue:setPaused(true, 'Restarting in 5 minutes')
```

## Config

Everything else is in `config.lua`: grace length, reserved slots, timeouts, the card's title, banner image and tips, and every message players see if you want to translate them.

## Addons

- [fiveload](https://github.com/1amZach/fiveload): a loading screen that shows players how long they waited and their priority.
- [fivecord](https://github.com/1amZach/fivecord): run the server from Discord. Bans, reports, staff chat, restarts and more with slash commands. joinqueue works the same with or without it.

## Support

Made by **IamZach**. Questions, bugs or ideas: [discord.gg/agn](https://discord.gg/agn)

## License

MIT
