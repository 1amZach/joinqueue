-- Loaded on the server only, nothing in here reaches players.
Config = {}

-- Higher points get in first. The label is shown on the queue card.
Config.tiers = {
    staff = { points = 100, label = 'Staff' },
    vip = { points = 50, label = 'VIP' },
    booster = { points = 25, label = 'Server Booster' },
}

-- Any identifier works: license:, discord:, fivem:, steam:, ...
Config.priority = {
    -- ['license:0123456789abcdef'] = 'staff',
}

-- Tiers can also come from aces, named joinqueue.<tier>:
--   add_ace group.admin joinqueue.staff allow
--   add_principal identifier.discord:123456789 group.admin

-- Give priority from Discord roles. The bot needs to be in your guild with the
-- Server Members intent turned on. Put the token in server.cfg, not here:
--   set joinqueue_discord_token "your bot token"
Config.discord = {
    enabled = false,
    guild = '',
    roles = {
        -- ['role id'] = 'vip',
    },
    requireMember = false, -- only let people in who are in the guild
}

-- Players who drop or crash get bumped up for a while so they can get back in.
Config.grace = {
    enabled = true,
    minutes = 5,
    points = 75,
    label = 'Reconnecting',
}

-- Slots only priority players can take. 2 here means regular players stop at maxclients - 2.
Config.reservedSlots = 0

-- Seconds after the resource starts before anyone is let in, so the rest of the server can finish starting.
Config.joinDelay = 20

-- Seconds someone can take to load in after leaving the queue before their slot is freed.
Config.connectTimeout = 600

-- Seconds a place in line is kept if someone's game closes while they wait.
Config.holdSpot = 120

-- Seconds without hearing from a player in the queue before they count as gone.
Config.queueTimeout = 60

Config.requireDiscord = false

-- Only players with some priority can join.
Config.whitelistOnly = false

-- Show the number of people waiting in front of the server name, like "[4] My Server".
Config.hostnameCount = false

Config.card = {
    title = false, -- false uses sv_projectName, then sv_hostname
    image = false, -- url of a banner, about 3:1 looks best
    discord = false, -- your server's invite, e.g. 'https://discord.gg/yourserver'
    tips = {
        'You keep your place if your game closes, as long as you come back within 2 minutes.',
        'Crashed? You get a few minutes of priority to get back in.',
        'Read the rules on our Discord while you wait.',
    },
}

Config.messages = {
    checking = 'Checking your details...',
    noLicense = 'We couldn\'t find your Rockstar license. Restart FiveM and try again.',
    needDiscord = 'Open Discord before joining so we can check your roles.',
    notMember = 'You need to be in our Discord to join.',
    whitelist = 'This server is whitelisted.',
    left = 'You left the queue.',
    removed = 'You were removed from the queue.',
    joining = 'Joining...',
    starting = 'The server is starting, hang tight.',
    paused = 'The queue is paused',
}
