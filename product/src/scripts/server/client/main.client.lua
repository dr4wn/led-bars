local CollectionService = game:GetService('CollectionService')

local instanceIdentifier = script.Parent:GetAttribute('identifier')
if not instanceIdentifier then
    return
end

local baseProductString = 'dr4wn-led-bars-'
local productFolder = CollectionService:GetTagged(baseProductString..instanceIdentifier)[1]
local prefix = '[LED Bars: Main]'

print(prefix..' '..tostring(script.Name)..' file given to client.')

local fixtureFolder = productFolder:FindFirstChild('fixtures')
if not fixtureFolder then
    return
end

local scriptsFolder = productFolder:FindFirstChild('scripts')
if not scriptsFolder then
    return
end

local sharedFolder = scriptsFolder:FindFirstChild('shared')
if not sharedFolder then
    return
end

local configurationPath = productFolder.configuration:FindFirstChild('configuration')
if not configurationPath then
    return
end

local Configuration = require(configurationPath)

local Utility = require(
    sharedFolder:FindFirstChild('Utility')
)()

local Light, StaticFunctions, FixtureController = unpack(
    require(
        sharedFolder:FindFirstChild('Light')
    )()
)

local Effect, EffectController, Effects = unpack(
    require(
        sharedFolder:FindFirstChild('Effect')
    )()
)

local EffectContainer = EffectController.new()
local FixtureContainer = FixtureController.new()

local TILT_DIVISOR = 500

local fixtureData = { effects = {}, colorMode = 'all' }
local DEUBGGING_ENABLED = false

local function debug(event, msg, callback)
    if not DEUBGGING_ENABLED then return end
    if not callback then callback = warn end
    callback('[{event} called] {msg}')
end

function getPhaseForLight(lightName, group, cellsPerLight)
    local phaseForLight = {}
    for cell = 1, cellsPerLight do
        local basePhase = (group == 1) and cell or (cellsPerLight + 1 - cell)
        table.insert(phaseForLight, basePhase + cellsPerLight * (lightName - 1))
    end
    return phaseForLight
end

function getContinuousPhase(lightName, cellsPerLight)
    local phaseForLight = {}
    for cell = 1, cellsPerLight do
        local phase = (lightName - 1) * cellsPerLight + cell - 1
        table.insert(phaseForLight, phase)
    end
    return phaseForLight
end

local function populate(value, amount)
    local tbl = {}

    for i = 1, math.floor(amount) do
        tbl[i] = value
    end

    return tbl
end

for index, fixture in fixtureFolder:GetChildren() do
    local fixtureInstances = fixture:FindFirstChild('Instances', true)
    local cells = fixtureInstances.Lens:GetChildren()
    local fixtureId = fixture:GetAttribute('FixtureID') or 1
    local groupId = fixture:GetAttribute('GroupID') or 1
    local secondaryId = fixture:GetAttribute('SecondaryID') or 1

    table.sort(cells, function(a, b)
        return tonumber(a.Name) < tonumber(b.Name)
    end)

    local beamBrightness = tonumber(Configuration.beamBrightness) or 0.1

    for _, beam in fixtureInstances.Lens:GetChildren() do
        if not beam.light:IsA("Beam") then
            continue
        end

        beam.light.Brightness = beamBrightness
    end

    local light = Light.new({
        personality = {
            name = fixture.Name,
            groupId = groupId,
            fixtureId = fixtureId,
            secondaryId = secondaryId,
            index = index,
            interleave = (fixtureId - 1) % 8 + 1,
            generateInterleave = function(fixtureId, interleavePattern)
                return (fixtureId - 1) % interleavePattern + 1
            end,
            useBeam = Configuration.stylistic.useBeam
        },
        instances = {
            model = fixture,
            cells = cells,
            motors = {
                tilt = fixtureInstances.TiltMotor
            },
            spot = fixtureInstances.Light.SurfaceLight,
            possibleAttachments = fixture.Instances.Light:GetChildren()
        },
        extras = {
            phase = getPhaseForLight(fixtureId, groupId, 16),
            continuousPhase = getContinuousPhase(fixture:GetAttribute('SecondaryID'), 16),
            fixturePhase = populate(fixtureId, 16),
        }
    })

    FixtureContainer:Append(light)
    debug('creation', 'fixture created and appended', warn)
end

for effectData, callback in Effects do
    local effect = Effect.new(
        Utility:createEffectStructure(effectData, callback, { instances = FixtureContainer:Get() })
    )

    EffectContainer:Append(effect)
    debug('creation', 'effect created and appended', warn)
end

local function setPosition(positionIndex)
    if #Configuration.positions == 0 then return end
    local position = Configuration.positions[positionIndex] or Configuration.positions[1]

    if type(position) ~= 'table' then
        if type(position) == 'function' then
            error(
                string.format('type %s cannot be a %s!', position, type(position))
            )
        end

        return warn('[LED Bars] "position" was not set to a table! ')
    end

    debug('position', 'setting position to position index {positionIndex}', warn)

    local positionCategory = position.mode

    local categories = {
        all = function(light)
            light.instances.motors.tilt.DesiredAngle = position.data[1]
        end,
        custom = function(light)
            local currentInterleave = light.personality.interleave
            local fixtureId = light.personality.fixtureId

            local interleavePosition = currentInterleave == #position.data and currentInterleave or light.personality.generateInterleave(fixtureId, #position.data)

            light.instances.motors.tilt.DesiredAngle = position.data[interleavePosition]
        end,
        default = function(light)
            local isEven = light:isEven() and 1 or 2
            light.instances.motors.tilt.DesiredAngle = position.data[isEven]
        end,
    }

    for _, fixture in FixtureContainer:Get() do
        local _category = categories[positionCategory] and categories[positionCategory] or categories.default
        _category(fixture)
    end
end

local function setColor(arguments, isFirstReplicated)
    local isModeUnequalToAll = arguments.colorMode ~= 'all'
    local twoIndexesInColorTable = #arguments.colors == 2

    for _, light in FixtureContainer:Get() do
        if (isModeUnequalToAll and twoIndexesInColorTable and isFirstReplicated) then
            Utility:setColor(light, 'evenOdd', arguments)
        else
            Utility:setColor(light, arguments.colorMode, arguments)
        end
    end
end

local function setBPM(name, value)
    debug('bpm', 'setting bpm data to name-{name}:bpm-{value}', warn)

    for _, effect in EffectContainer:Get() do
        if not effect.personality.editable.bpm then continue end
        local isCategoryMatch = effect.personality.category == name
        local isMovementCategory = name == 'movement'

        if not isCategoryMatch then continue end
        debug('bpm', 'setting bpm of {effect.personality.name} to {value}')
        effect.personality.bpm = value

        if isMovementCategory then
            for _, fixture in FixtureContainer:Get() do
                fixture.instances.motors.tilt.MaxVelocity = value / TILT_DIVISOR
            end
        end
    end
end

local function setPhase(phaseName, value)
    debug('phase', 'setting phase data to {phaseName}:{value}', warn)

    for _, effect in EffectContainer:Get() do
        if not effect.personality.editable.phase then continue end
        local isCategoryMatch = effect.personality.category == phaseName

        if not isCategoryMatch then continue end
        effect.personality.phase = value
    end
end

local function setColorFX(color)
    for _, effect in EffectContainer:Get() do
        local isCategoryMatch = effect.personality.category == 'color'

        if not isCategoryMatch then continue end
        effect.personality.colorSwitch = color
    end
end

local function setLimit(limitName, value)
    for _, effect in EffectContainer:Get() do
        if not effect.personality.editable.limit then continue end
        local effectLimit = effect.personality.limits[limitName]

        if not effectLimit then continue end
        effectLimit = value
    end
end

local function setDimmer(arguments)
    local staticFunction = StaticFunctions[arguments.func]
    if not staticFunction then return end

    StaticFunctions.Cancel()
    StaticFunctions[arguments.func]({
        mouseButton = arguments.mouseButton,
        fixtures = FixtureContainer:Get()
    })
end

local function setEffect(arguments)
    for _, effectData in arguments.effects do
        if effectData.on then
            EffectContainer:runEffect(effectData.effectName)
            fixtureData.effects[effectData.effectName] = effectData.buttonReference
        else
            EffectContainer:stopEffect(effectData.effectName)
            fixtureData.effects[effectData.effectName] = nil
        end
    end

    productFolder.events.Data:Fire({ effects = arguments.effects })
end

local function setSpot(isOn)
    for _, fixture in FixtureContainer:Get() do
        fixture.instances.spot.Enabled = isOn

        if fixture.personality.useBeam then
            for i = 1, #fixture.instances.cells do
                fixture.instances.cells[i].light.Enabled = isOn
            end
        end
    end
end

local function listenToEvents()
    productFolder.events.Listener.OnClientEvent:Connect(function(method, ...)

        local methods = {
            replicator = function(...)
                local _ = ... local data = _.data
                local tempEffectContainer = {}

                setPosition(data.currentPosition)

                if data.lightOn then
                    setDimmer({ func = 'Power', mouseButton = 'MouseButton1Down' })
                else
                    setDimmer({ func = 'Power', mouseButton = 'MouseButton2Click' })
                end

                setSpot(data.spotOn)
                setColorFX(data.color.colorFX)

                if data.color then
                    setColor(data.color, true)
                end

                for bpmKey, bpmValue in data.bpm do
                    setBPM(bpmKey, bpmValue)
                end

                for phaseKey, phaseValue in data.phase do
                    setPhase(phaseKey, phaseValue)
                end

                for limitKey, limitValue in data.limit do
                    setLimit(limitKey, limitValue)
                end

                for effectName, buttonReference in data.effects do
                    local effectTemplate = {
                        effectName = effectName,
                        buttonReference = buttonReference,
                        on = true
                    }
                    EffectContainer:runEffect(effectName)
                    table.insert(tempEffectContainer, effectTemplate)
                end

                productFolder.events.Data:Fire({ effects = tempEffectContainer })
            end,
            dimmer = function(...)
                local arguments = ...
                setDimmer(arguments)
            end,
            effect = function(...)
                local arguments = ...
                setEffect(arguments)
            end,
            color = function(...)
                local arguments = ...

                if arguments.colorMode then
                    fixtureData.colorMode = arguments.colorMode
                end

                if arguments.colors then
                    setColor(arguments)
                end
            end,
            colorFX = function(...)
                local color = ...
                setColorFX(color)
            end,
            bpm = function(...)
                local arguments = ...
                setBPM(arguments.valueName, arguments.value)
            end,
            spot = function(...)
                local isOn = ...
                setSpot(isOn)
            end,
            phase = function(...)
                local arguments = ...
                setPhase(arguments.phaseName, arguments.value)
            end,
            limit = function(...)
                local arguments = ...
                setLimit(arguments.valueName, arguments.value)
            end,
            position = function(...)
                local positionIndex = ...
                local _positionIndex = positionIndex or 1
                setPosition(_positionIndex)
            end
        }

        if not methods[method] then
            return
        end

        methods[method](...)
    end)
end

function main()
    listenToEvents()
end

main()