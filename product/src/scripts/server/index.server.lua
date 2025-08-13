local MarketplaceService = game:GetService('MarketplaceService')
local CollectionService = game:GetService('CollectionService')
local GroupService = game:GetService('GroupService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')

local prefix = '[LED Bars: Main]'

local productFolderPath = script.Parent.Parent.Parent
local panelPart = productFolderPath.panels:FindFirstChildWhichIsA('Part')

panelPart:FindFirstChildWhichIsA('SurfaceGui'):Destroy()

local fixtureData = {
    identifier = HttpService:GenerateGUID(false)..tostring(DateTime.now().UnixTimestampMillis - (math.floor(math.random() * 90000))),
    locations = {
        panel = productFolderPath.panels:FindFirstChildWhichIsA('Part'),
        lights = productFolderPath.fixtures,
        events = productFolderPath.events,
        scripts = productFolderPath.scripts,
        shared = productFolderPath.scripts.shared,
        config = productFolderPath.configuration.configuration,
        templates = productFolderPath.templates,
    },
    administrators = {},
    effectData = {
        ['Random Strobe'] = { reset = true, parameters = {'Intensity'} },
        ['Random Fade'] = { reset = true, parameters = {'Intensity'} },
        ['Strobe'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_1'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_2'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_3'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_4'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_5'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_6'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_7'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_8'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_9'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_10'] = { reset = true, parameters = {'Intensity'} },
        ['Effect_11'] = { reset = true, parameters = {'Intensity', 'Position'} },
        ['Effect_12'] = { reset = true, parameters = {'Position'} },
        ['Effect_13'] = { reset = true, parameters = {'Position'} },
        ['Effect_14'] = { reset = true, parameters = {'Position'} },
        ['Effect_15'] = { reset = true, parameters = {'Position'} },
        ['Effect_16'] = { reset = true, parameters = {'Position'} },
        ['Effect_17'] = { reset = true, parameters = {'Color'} },
        ['Effect_18'] = { reset = true, parameters = {'Color'} },
        ['Effect_19'] = { reset = true, parameters = {'Color'} },
        ['Effect_21'] = { reset = true, parameters = {'Color'} },
        ['Effect_22'] = { reset = true, parameters = {'Color'} },
        ['Effect_23'] = { reset = true, parameters = {'Color'} },
    },
    libs = {},
    scripts = {},
    storage = {
        lightOn = false,
        fixtureApiOpened = false,
        spotOn = true,
        color = { colors = { Color3.new(1, 1, 1) }, colorMode = 'all', colorFX = Color3.new(1, 1, 1) },
        currentPosition = 1,
        bpm = { dimmer = 60, movement = 60, color = 60, iris = 60 },
        phase = { dimmer = 1, movement = 1, color = 1, iris = 1 },
        limit = { tilt = 1 },
        effects = {},
    }
}

local function createEvents()
    local listener = Instance.new('RemoteEvent', fixtureData.locations.events)
    listener.Name = 'Listener'
    local data = Instance.new('BindableEvent', fixtureData.locations.events)
    data.Name = 'Data'
end

local function warnForStreamingEnabled()
    if not game.Workspace.StreamingEnabled then return end

    for _ = 1, 5 do
        warn(
            table.concat({
                '',
                '-——-——-——-——-——-——-——-—',
                prefix..' Warning!',
                'StreamingEnabled is set to true. Our fixtures are',
                'not built for StreamingEnabled games, you may experience issues.',
                '-——-——-——-——-——-——-——-—',
            }, '\n')
        )
    end
end

local function streamingEnabledFailSafe()
    return not fixtureData.libs.configuration.ignoreStreamingEnabled and game.Workspace.StreamingEnabled
end

local function getButtonReference(effectName)
    assert(
        type(effectName) == 'string', 'effectName was not  a string!'
    )

    local panel = fixtureData.locations.panel
    if not panel then
        return
    end

    local interface = panel:FindFirstChild('Interface_Main')
    if not interface then
        return
    end

    local path = interface.holster.main.effect
    if not path then
        return
    end

    local effectPath = path:FindFirstChild(effectName)
    return effectPath
end

local methods = {
    dimmer = function(...)
        local arguments = ...
        fixtureData.storage.lightOn = arguments.lightOn
        fixtureData.locations.events.Listener:FireAllClients('dimmer', arguments)
    end,
    effect = function(...)
        local arguments = ...
        local container = {}

        container.effects = arguments.effects

        for _, effectTable in arguments.effects do
            if not effectTable.buttonReference then
                continue
            end

            if type(effectTable.buttonReference) == 'string' then
                effectTable.buttonReference = getButtonReference(effectTable.buttonReference)
            end

            if effectTable.on then
                fixtureData.storage.effects[effectTable.effectName] = effectTable.buttonReference
            else
                fixtureData.storage.effects[effectTable.effectName] = nil
                local dataPath = fixtureData.effectData[effectTable.effectName]

                if dataPath then
                    if not dataPath.reset then continue end
                    resetParameter(dataPath.parameters, fixtureData.locations.events)
                end
            end
        end

        fixtureData.locations.events.Listener:FireAllClients('effect', container)
    end,
    color = function(...)
        local arguments = ...

        fixtureData.storage.color = fixtureData.libs.Utility:handleColorChange(arguments, fixtureData.storage.color)

        fixtureData.locations.events.Listener:FireAllClients('color', {
            colorMode = fixtureData.storage.color.colorMode,
            colors = fixtureData.storage.color.colors
        })
    end,
    colorFX = function(...)
        local color = ...
        fixtureData.storage.color.colorFX = color
        fixtureData.locations.events.Listener:FireAllClients('colorFX', color)
    end,
    bpm = function(...)
        local arguments = ...

        local loweredName = string.lower(arguments.valueName)
        fixtureData.storage.bpm[loweredName] = arguments.value
        fixtureData.locations.events.Listener:FireAllClients('bpm', { valueName = loweredName, value = arguments.value })
    end,
    spot = function(...)
        local isOn = ...
        fixtureData.storage.spotOn = isOn
        fixtureData.locations.events.Listener:FireAllClients('spot', fixtureData.storage.spotOn)
    end,
    phase = function(...)
        local arguments = ...

        local phaseName = arguments.phaseName
        local value = tonumber(arguments.value) or 1

        fixtureData.storage.phase[phaseName] = value

        fixtureData.locations.events.Listener:FireAllClients('phase', { phaseName = phaseName, value = value })
    end,
    position = function(...)
        local positionIndex = ...
        fixtureData.storage.currentPosition = positionIndex
        fixtureData.locations.events.Listener:FireAllClients('position', fixtureData.storage.currentPosition)
    end,
    reset = function(...)
        local effectHolster = {}
        resetParameter({'Intensity', 'Position', 'Color'}, fixtureData.locations.events)

        for effectName, buttonReference in fixtureData.storage.effects do
            local tableConstruct = {
                buttonReference = buttonReference,
                effectName = effectName,
                on = false
            }
            table.insert(effectHolster, tableConstruct)
        end

        fixtureData.locations.events.Listener:FireAllClients('effect', { effects = effectHolster })
    end,
    fade = function(...)
        local arguments = ...
        fixtureData.locations.shared:SetAttribute('time', arguments.value)
    end,
    customCallback = function(...)
        local arguments = ...
        local callbackName = arguments.callbackName
        fixtureData.apiRef.runCallback(callbackName, arguments.index)
    end
}

local function openFixtureApiConnection()
    if fixtureData.storage.fixtureApiOpened then return end
    fixtureData.storage.fixtureApiOpened = true

    local apiPath = script.Parent:FindFirstChild('api')
    if not apiPath then
        return error(prefix, 'API not found and/or path is incorrect.')
    end

    local FixtureAPI = require(apiPath)
    if not FixtureAPI then
        error(prefix, 'Failed to open api connection.')
        return
    end

    FixtureAPI.init()

    for name, callback in methods do
        FixtureAPI.connectEvent(name, callback)
    end

    return FixtureAPI
end

local function whitelistCheck(player)
    if not fixtureData.libs.configuration.whitelistEnabled then
        return true
    end

    for _, user in fixtureData.libs.configuration.panelWhitelist do
        if type(user) == 'string' then
            if player.Name == user then return true end
        end

        if type(user) == 'number' then
            if player.UserId == user then return true end
        end

        if type(user) == 'table' and user[1] == 'gamepass' then
            local success, userOwnsGamepass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, user[2])
            end)

            if success and userOwnsGamepass then return true end
        end

        local groups = GroupService:GetGroupsAsync(player.UserId)

        if type(user) == 'table' and user[1] == 'group' then
            local groupInfo = user[2]

            for _, group in groups do
                if group.Id ~= groupInfo.groupId then continue end

                local rankInGroup = player:GetRankInGroup(group.Id)

                if not groupInfo.useRanks then return true end

                for _, rankId in groupInfo.ranks do
                    if rankId == rankInGroup then return true end
                end
            end
        end
    end

    return false
end

function resetParameter(parameters, eventsFolder)
    local callbacks = {
        ['Intensity'] = function()
            fixtureData.storage.lightOn = false

            eventsFolder.Listener:FireAllClients('dimmer', {
                func = 'Power',
                mouseButton = 'MouseButton2Down',
                lightOn = false
            })
        end,
        ['Position'] = function()
            fixtureData.storage.currentPosition = 1
            eventsFolder.Listener:FireAllClients('position', 1)
        end,
        ['Color'] = function()
            fixtureData.storage.color.colors = { Color3.new(1, 1, 1) }
            fixtureData.storage.color.colorMode = 'all'

            eventsFolder.Listener:FireAllClients('color', {
                colorMode = fixtureData.storage.color.colorMode,
                colors = fixtureData.storage.color.colors
            })
        end
    }

    for _, callbackName in parameters do
        callbacks[callbackName]()
    end
end

local function setupPlayer(player)
    local guiHolster = Instance.new('SurfaceGui')
    guiHolster.Name = 'led-bar-holster_'..fixtureData.identifier
    guiHolster.ResetOnSpawn = false
    guiHolster:SetAttribute('identifier', fixtureData.identifier)

    local playerGui = player:WaitForChild('PlayerGui', 10)

    if not playerGui then
        return player:Kick(
            table.concat({
                '',
                prefix,
                'There was a problem while indexing your PlayerGui, please rejoin.',
            }, '\n')
        )
    end

    local wl =  whitelistCheck(player)

    if wl then
        if not fixtureData.administrators[player.UserId] then
            fixtureData.administrators[player.UserId] = true
        end
        fixtureData.locations.scripts.server.client.admin:Clone().Parent = guiHolster
    end

    fixtureData.locations.scripts.server.client.main:Clone().Parent = guiHolster
    guiHolster.Parent = playerGui

    fixtureData.locations.events.Listener:FireClient(player, 'replicator', { onFirstJoin = true, data = fixtureData.storage })
end

local function isAdmin(player)
    return fixtureData.administrators[player.UserId] ~= nil
end

local function handleNonAdmin(player)
    if not fixtureData.libs.configuration.kickTamperingUsers then
        return
    end

    local kickMessage = string.len(fixtureData.libs.configuration.customKickMessage) ~= 0 and fixtureData.libs.configuration.customKickMessage or 'kicked for tampering'

    player:Kick(
        table.concat({
            '',
            '-——-——-——-——-——-——-——-—',
            kickMessage,
            '-——-——-——-——-——-——-——-—',
        }, '\n')
    )
end

local function listenToEvents()
    local eventsFolder = fixtureData.locations.events
    if not eventsFolder then
        return error(prefix, '"eventsFolder" path not found and/or is misplaced.')
    end

    eventsFolder.Listener.OnServerEvent:Connect(function(player, method, ...)
        if not isAdmin(player) then return handleNonAdmin(player) end

        if not methods[method] then
            return
        end

        methods[method](...)
    end)
end

local function tagObjects()
    local tag = 'dr4wn-led-bars-' .. fixtureData.identifier
    CollectionService:AddTag(productFolderPath, tag)

    productFolderPath.scripts.shared:SetAttribute('identifier', fixtureData.identifier)
end

function init()
    local utilityPath = fixtureData.locations.shared:FindFirstChild('Utility')
    if not utilityPath then
        return error(prefix, 'Could not find utility file and/or path is incorrect.')
    end

    fixtureData.libs.Utility = require(
        fixtureData.locations.shared.Utility
    )()

    fixtureData.libs.configuration = require(
        fixtureData.locations.config
    )

    warnForStreamingEnabled()

    if streamingEnabledFailSafe() then
        return
    end

    local interface = fixtureData.locations.templates:FindFirstChild('Interface_Main')
    local panel = fixtureData.locations.panel

    if not interface or not panel then
        return error(prefix, `Failed to locate panel or interface. \nPanel Exists?: {panel ~= nil}\n Interface Exists?: {interface ~= nil}`)
    end

    interface.Parent = panel
    interface.Adornee = panel

    createEvents()
    tagObjects()
    listenToEvents()

    if fixtureData.libs.configuration.usingApi then
        fixtureData.apiRef = openFixtureApiConnection()
    end

    Players.PlayerAdded:Connect(function(player)
        setupPlayer(player)
    end)

    for _, player in Players:GetPlayers() do
        setupPlayer(player)
    end
end

init()