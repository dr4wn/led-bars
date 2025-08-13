local TweenService = game:GetService('TweenService')

local Light = {}
Light.__index = Light

local FixtureController = {}
FixtureController.__index = FixtureController

local allowedParameters = {
    Intensity = {'setIntensity', true},
    ['Intensity All'] = {'setIntensityAll', true},
    Tilt = {'setTiltMotor', true},
    Color = {'setColor', true},
    ['Color All'] = {'setColorAll', true},
}

local fixtureClamp = {
    Intensity = {
        min = 0,
        max = 1,
    },
    ['Intensity All'] = {
        min = 0,
        max = 1,
    },
    Tilt = {
        min = math.rad(-135),
        max = math.rad(135),
    },
    Color = 'ignore',
    ['Color All'] = 'ignore',
}

local prefix = '[LED Bars: Light.lua]'


function Light.new(arguments)
    if not arguments then
        return
    end

    local self = {
        personality = arguments.personality,
        instances = arguments.instances,
        extras = {
            lastSavedColor = Color3.new(1, 1, 1),
            brightnessMultiplier = arguments.instances.model:GetAttribute('BrightnessMultiplier'),
            phase = arguments.extras.phase,
            continuousPhase = arguments.extras.continuousPhase,
            fixturePhase = arguments.extras.fixturePhase
        },
    }
    return setmetatable(self, Light)
end

local function calculateAverage(instances)
    local totalCount = #instances
    local totalNormalizedTransparency = 0

    for _, item in ipairs(instances) do
        totalNormalizedTransparency = totalNormalizedTransparency + (1 - item.Transparency)
    end

    if totalCount > 0 then
        local averageNormalizedTransparency = totalNormalizedTransparency / totalCount
        local maxBrightness = 5
        local scaledBrightness = averageNormalizedTransparency * maxBrightness

        local gamma = 0.5
        local correctedBrightness = scaledBrightness ^ gamma

        return math.min(maxBrightness, math.max(0, correctedBrightness))
    else
        return 0
    end
end

local function calcuateAverageColor(instances)
    local r, g, b = 0, 0, 0
    for _, item in instances do
        r = r + item.Color.R
        g = g + item.Color.G
        b = b + item.Color.B
    end

    return Color3.new(r / #instances, g / #instances, b / #instances)
end

function Light.setIntensity(self, value, cell)
    self.instances.cells[cell].Transparency = value
    local collectiveBrightness = calculateAverage(self.instances.cells)
    self.instances.spot.Brightness = (collectiveBrightness) * self.extras.brightnessMultiplier

    self.instances.spot.Range = math.clamp((1 - value)  * 60, 35, 60)
    self.instances.spot.Angle = math.clamp((1 - value ) * 50, 35, 135)

    local attachments = self.instances.possibleAttachments
    for _, attachment in attachments do
        if not attachment:IsA('Attachment') then continue end
        if attachment.Name ~= "External" then continue end
        attachment.Spot.Brightness = collectiveBrightness * self.extras.brightnessMultiplier
    end

    if not self.personality.useBeam then
        return
    end

    self.instances.cells[cell].light.Transparency = NumberSequence.new(value, 1)
end

function Light.setIntensityAll(self, value)
    for i = 1, #self.instances.cells do
        self.instances.cells[i].Transparency = value
        if not self.personality.useBeam then
            continue
        end

        self.instances.cells[i].light.Transparency = NumberSequence.new(value, 1)
    end

    local collectiveBrightness = (( 1 - value) * 1.6)
    self.instances.spot.Brightness = collectiveBrightness * self.extras.brightnessMultiplier
    self.instances.spot.Range = math.clamp((1 - value) * 60, 35, 60)
    self.instances.spot.Angle = math.clamp((1 - value) * 50, 45, 135)

    local attachments = self.instances.possibleAttachments
    for _, attachment in attachments do
        if not attachment:IsA('Attachment') then continue end
        if attachment.Name ~= "External" then continue end
        attachment.Spot.Brightness = collectiveBrightness * self.extras.brightnessMultiplier
    end
end

function Light.setTiltMotor(self, value)
    self.instances.motors.tilt.DesiredAngle = value
end

function Light.setColor(self, color, cell)
    self.instances.cells[cell].Color = color

    local _color =  calcuateAverageColor(self.instances.cells)
    self.instances.spot.Color = _color

    local attachments = self.instances.possibleAttachments
    for _, attachment in attachments do
        if not attachment:IsA('Attachment') then continue end
        if attachment.Name ~= "External" then continue end
        attachment.Spot.Color = _color
    end

    if not self.personality.useBeam then
        return
    end

    self.instances.cells[cell].light.Color = ColorSequence.new(color)
end

function Light.setColorAll(self, value)
    for i = 1, #self.instances.cells do
        self.instances.cells[i].Color = value

        if not self.personality.useBeam then
            continue
        end
        self.instances.cells[i].light.Color = ColorSequence.new(value)
    end

    local attachments = self.instances.possibleAttachments
    for _, attachment in attachments do
        if not attachment:IsA('Attachment') then continue end
        if attachment.Name ~= "External" then continue end
        attachment.Spot.Color = value
    end

    self.instances.spot.Color = value
end

function Light:isEven()
    return self.personality.fixtureId % 2 == 0
end

function Light:isLeft()
    return self.personality.groupId == 1
end

function Light:setValue(parameter, value, cell)
    local parameterData = allowedParameters[parameter]
    if not parameterData then return warn('NO!') end
    if not parameterData[2] then return end

    local clampData = fixtureClamp[parameter]

    if clampData ~= 'ignore' then
        value = math.clamp(
            value, clampData.min, clampData.max
        )
    end

    local callbackName = parameterData[1]
    if not callbackName then return end


    local success, message = pcall(function()
        return Light[callbackName](self, value, cell)
    end)

    if not success and message then
        warn(prefix, message)
    end
end

function FixtureController.new()
    local self = {
        fixtures = {}
    }
    return setmetatable(self, FixtureController)
end

function FixtureController:Append(fixture)
    self.fixtures[#self.fixtures + 1] = fixture
end

function FixtureController:Get()
    if not self.fixtures then
        warn(
            table.concat(
                {
                    '',
                    '-——-——-——-——-——-——-——-——-——-——-——-——-——',
                    prefix,
                    'There are no fixtures to sort. Are they in the correct folder?',
                    '-——-——-——-——-——-——-——-——-——-——-——-——-——',
                    ''
                },
            '\n')
        )
        return {'No fixtures!'}
    end

    table.sort(self.fixtures, function(a, b)
        return tonumber(a.personality.fixtureId) > tonumber(b.personality.fixtureId)
    end)

    return self.fixtures
end

local connection, tween, completed
local fadeIdentifier = ('dr4wn-led-bars'..script.Parent:GetAttribute('identifier'))

local function cancelFade()
    if connection or tween or completed then
        tween:Cancel() tween = nil
        connection:Disconnect() connection = nil
        completed:Disconnect() completed = nil

        for _, item in game.ReplicatedFirst:GetChildren() do
            if not item:IsA('NumberValue') then continue end
            if item.Name ~= fadeIdentifier then continue end

            item:Destroy()
        end
    end
end

local function setFade(fixtures, initialValue, targetValue)
    local NumberValue = Instance.new('NumberValue', game.ReplicatedFirst)
    NumberValue.Value = initialValue
    NumberValue.Name = fadeIdentifier

    local function setIntensity(intensity)
        for _, fixture in fixtures do
            fixture:setValue('Intensity All', intensity)
        end
    end

    setIntensity(initialValue)

    tween = TweenService:Create(
        NumberValue,
        TweenInfo.new(
            script.Parent:GetAttribute('time')
        ),
        {Value = targetValue}
    )

    tween:Play()
    connection = NumberValue:GetPropertyChangedSignal('Value'):Connect(function()
        setIntensity(NumberValue.Value)
    end)

    completed = tween.Completed:Connect(function()
        connection:Disconnect() connection = nil
        completed:Disconnect() completed = nil
        NumberValue:Destroy()
        tween = nil
    end)
end

local StaticFunctions = {
    ['Cancel'] = function()
        cancelFade()
    end,
    ['Power'] = function(arguments)
        local lightUpdater = {
            ['MouseButton1Down'] = function()
                for _, fixture in  arguments.fixtures do
                    fixture:setValue('Intensity All', 0)
                end
            end,
            ['MouseButton1Up'] = function()
                for _, fixture in arguments.fixtures do
                    fixture:setValue('Intensity All',  1)
                end
            end,
            ['MouseButton2Down'] = function()
                for _, fixture in arguments.fixtures do
                    fixture:setValue('Intensity All',  1)
                end
            end,
            ['MouseButton2Click'] = function()
                for _, fixture in arguments.fixtures do
                    fixture:setValue('Intensity All',  1)
                end
            end,
        }
        if not arguments.mouseButton then return end
        lightUpdater[arguments.mouseButton]()
    end,

    ['Fade In'] = function(arguments)
        local fixtures = {}
        for _, fixture in arguments.fixtures do
            fixtures[#fixtures + 1] = fixture
        end
        setFade(fixtures, 1, 0)
    end,

    ['Fade Out'] = function(arguments)
        local fixtures = {}
        for _, fixture in arguments.fixtures do
            fixtures[#fixtures + 1] = fixture
        end
        setFade(fixtures, 0, 1)
    end,
    ['Hold A/B'] = function(arguments)
        local lightUpdater = {
            ['MouseButton1Down'] = function()
                for _, fixture in  arguments.fixtures do
                    if not fixture:isEven() then continue end
                    fixture:setValue('Intensity All', 0)
                end
            end,
            ['MouseButton1Up'] = function()
                for _, fixture in arguments.fixtures do
                    if not fixture:isEven() then continue end
                    fixture:setValue('Intensity All',  1)
                end
            end,
            ['MouseButton2Down'] = function()
                for _, fixture in  arguments.fixtures do
                    if fixture:isEven() then continue end
                    fixture:setValue('Intensity All', 0)
                end
            end,
            ['MouseButton2Up'] = function()
                for _, fixture in arguments.fixtures do
                    if fixture:isEven() then continue end
                    fixture:setValue('Intensity All',  1)
                end
            end,
        }
        if not arguments.mouseButton then return end
        lightUpdater[arguments.mouseButton]()
    end,

    ['Pulse A/B'] = function(arguments)
        local lightUpdater = {
            ['MouseButton1Down'] = function()
                local fixtures = {}
                for _, fixture in arguments.fixtures do
                    if not fixture:isEven() then continue end
                    fixtures[#fixtures + 1] = fixture
                end
                setFade(fixtures, 0, 1)
            end,
            ['MouseButton2Down'] = function()
                local fixtures = {}
                for _, fixture in arguments.fixtures do
                    if fixture:isEven() then continue end
                    fixtures[#fixtures + 1] = fixture
                end
                setFade(fixtures, 0, 1)
            end,
        }
        if not arguments.mouseButton then return end
        lightUpdater[arguments.mouseButton]()
    end,

    ['Hold L/R'] = function(arguments)
        local lightUpdater = {
            ['MouseButton1Down'] = function()
                for _, fixture in  arguments.fixtures do
                    if not fixture:isLeft() then continue end
                    fixture:setValue('Intensity All', 0)
                end
            end,
            ['MouseButton1Up'] = function()
                for _, fixture in arguments.fixtures do
                    if not fixture:isLeft() then continue end
                    fixture:setValue('Intensity All',  1)
                end
            end,
            ['MouseButton2Down'] = function()
                for _, fixture in  arguments.fixtures do
                    if fixture:isLeft() then continue end
                    fixture:setValue('Intensity All', 0)
                end
            end,
            ['MouseButton2Up'] = function()
                for _, fixture in arguments.fixtures do
                    if fixture:isLeft() then continue end
                    fixture:setValue('Intensity All',  1)
                end
            end,
        }
        if not arguments.mouseButton then return end
        lightUpdater[arguments.mouseButton]()
    end,
    ['Fade Hold A/B'] = function(arguments)
        local lightUpdater = {
            ['MouseButton1Down'] = function()
                local fixtures = {}
                for _, fixture in arguments.fixtures do
                    if not fixture:isEven() then continue end
                    fixtures[#fixtures + 1] = fixture
                end
                setFade(fixtures, 1, 0)
            end,
            ['MouseButton1Up'] = function()
                local fixtures = {}
                for _, fixture in arguments.fixtures do
                    if not fixture:isEven() then continue end
                    fixtures[#fixtures + 1] = fixture
                end
                setFade(fixtures, 0, 1)
            end,
            ['MouseButton2Down'] = function()
                local fixtures = {}
                for _, fixture in arguments.fixtures do
                    if fixture:isEven() then continue end
                    fixtures[#fixtures + 1] = fixture
                end
                setFade(fixtures, 1, 0)
            end,
            ['MouseButton2Up'] = function()
                local fixtures = {}
                for _, fixture in arguments.fixtures do
                    if fixture:isEven() then continue end
                    fixtures[#fixtures + 1] = fixture
                end
                setFade(fixtures, 0, 1)
            end,
        }
        if not arguments.mouseButton then return end
        lightUpdater[arguments.mouseButton]()
    end
}

return {Light, StaticFunctions, FixtureController}



