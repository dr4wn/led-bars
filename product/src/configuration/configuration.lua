return {
    whitelistEnabled = false, -- boolean | "false" by default
    kickTamperingUsers = true, -- boolean | "true" by default
    customKickMessage = "",

    panelWhitelist = { -- number | string | table
        "usernames must be a string",
        "and userids must be a number",
        `aka no quotes or characters that make strings ! ->> "", '' <--`,
        1,

        {"gamepass", 1},

        {"group",
            {
                groupId = 1,
                useRanks = true,
                ranks = {1, 2, 3, 4, 5 ,6}
            }
        }
    },

    dev = {
        extraInfo = true,
        debug = true
    },

    ignoreStreamingEnabled = false,
    streamingEnabledWarning = true,
    usingApi = true,

    stylistic = {
        ripple = true,
        strokeAnimations = true,
        useBeam = true,
    },

    beamBrightness = 0.15,

    positions = {
        { mode = "all", data = { math.rad(0) } },
        { mode = "all", data = { math.rad(45) } },
        { mode = "all", data = { math.rad(90) } },
        { mode = "all", data = { math.rad(135) } },
        { mode = "all", data = { math.rad(45) } },
        { mode = "all", data = { math.rad(90) } },
        { mode = "all", data = { math.rad(135) } },
        { mode = "both", data = { math.rad(45), math.rad(90) } },
        { mode = "custom", data = { math.rad(90), math.rad(45), math.rad(15), math.rad(0) }},
        { mode = "custom", data = { math.rad(0), math.rad(45), math.rad(0), math.rad(45) }},
        { mode = "custom", data = { math.rad(35), math.rad(25), math.rad(15), math.rad(15), math.rad(25), math.rad(35) }},
        { mode = "custom", data = { math.rad(15), math.rad(25), math.rad(35), math.rad(45), math.rad(55), math.rad(65), math.rad(75), math.rad(85) }},
        { mode = "custom", data = { math.rad(90), math.rad(45), math.rad(15), math.rad(0) }},
    },

    --[[
        All of these are "technically" optional, but
        having all of them as optional would defeat the purpose.
        Leaving the design part optional as seen below would be the
        best, as they do not communicate anywhere except for the buttons.
    ]]

    btnExample = {
        name = "name",
        link = "cueLink",
        onClick = {"MouseButton1Click"},
        textColor = Color3.new(1, 1, 1),
        strokeColor = Color3.new(1, 1, 1),
        textTransparency = 0,
        strokeTransparency = 0,
    },

    customButtons = {
        {
            name = "Demo",
            link = "Demo",
            onClick = {"MouseButton1Down"},
        },
        {
            name = "Set Day",
            link = "Set Day",
            onClick = {"MouseButton1Down", "MouseButton1Up"},
        },
        {
            name = "Kick All",
            link = "Kick All",
            onClick = {"MouseButton1Down"},
        },
    }
}