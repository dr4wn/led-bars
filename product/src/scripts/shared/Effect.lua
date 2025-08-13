local RunService = game:GetService('RunService')

local Effect = {}
Effect.__index = Effect

local EffectController = {}
EffectController.__index = EffectController

local libraries = script.Parent:FindFirstChild('libs', true)
local LuaAdditions = require(libraries['lua-additions']:FindFirstChild('MainModule', true))

local dtCorrector = 0.01


local Waveforms = {
    ['Sine'] = function(step, phase)
        return (math.sin((2 * math.pi * step) + phase) * 0.5 + 0.5)
    end,
    ['Cosine'] = function(step, phase)
        return (math.cos((2 * math.pi * step) + phase) * 0.5 + 0.5)
    end,
    ['Flat High'] = function(step, phase)
        return 1
    end,
    ['Flat Low'] = function()
        return 0
    end,
    -- *other waveforms omitted*
}

function Effect.new(arguments)
    if not arguments then
        return
    end

    local self = {
        personality = arguments.personality,
        engine = {
            callback = arguments.engine.callback,
            waveform = Waveforms[arguments.engine.waveform] or Waveforms['Sine'],
            connection = nil,
            step = 0,
            total = 0,
            running = false,
        },
        extras = {
            instances = arguments.extras.instances,
            tempFixtures = {},
            clearedToRestart = true
        }
    }

    return setmetatable(self, Effect)
end

function Effect:isRunning()
    return self.engine.connection ~= nil
end

function Effect:start()
    if self:isRunning() then return end

    self.engine.running = true
    self.engine.connection = RunService.Heartbeat:Connect(function(deltaTime)
        self.engine.step += ((((((math.pi)) * (self.personality.bpm)) * self.personality.direction) * deltaTime) * dtCorrector) * self.personality.bpmMult
        self.engine.total += ((((((math.pi)) * (self.personality.bpm))) * deltaTime) * dtCorrector) * self.personality.bpmMult

        self.engine.callback(self, deltaTime)
    end)
end

function Effect:stop()
    if not self:isRunning() then return end

    self.engine.connection:Disconnect()
    self.engine.connection = nil
    self.engine.running = false
    self.engine.step = 0
    self.engine.total = 0
end

function EffectController.new()
    local self = {
        effects = {}
    }
    return setmetatable(self, EffectController)
end

function EffectController:Append(effect)
    self.effects[#self.effects + 1] = effect
end

function EffectController:runEffect(effectName)
    local effect = LuaAdditions.Table.find(self.effects, function(_effectName)
        return effectName == _effectName.personality.name
    end)

    if not effect then return end
    effect:start()
end

function EffectController:stopEffect(effectName)
    local effect = LuaAdditions.Table.find(self.effects, function(_effectName)
        return effectName == _effectName.personality.name
    end)

    if not effect then return end
    effect:stop()
end

function EffectController:Get()
    return self.effects
end

local callbacks = {
    effectCallback = function(self)
        for _, fixture in self.extras.instances do
            for cell = 1, #fixture.instances.cells do

                local form = self.engine.waveform(
                    self.engine.step,
                    (fixture.extras[self.personality.phaseSelection][cell] * self.personality.phase) * self.personality.phaseMult
                )

                fixture:setValue(self.personality.parameter, form, cell)
            end
        end
    end,
    regularMovement = function(self)
        for _, fixture in self.extras.instances do
            local form = self.engine.waveform(
                self.engine.step,
                (fixture.personality.fixtureId * self.personality.phase) * self.personality.phaseMult
            )

            fixture:setValue(self.personality.parameter, (form + .3) * 1.4)
        end
    end,
    -- *other callbacks omitted*
}

local function populateEffects(effects)
    local __effects = {}

    for _, effectData in effects do
        __effects[effectData] = effectData.callback or callbacks.effectCallback
    end

    return __effects
end

local Effects = populateEffects({
    -- *some effects omitted*
        {name='Effect_13', editableByPhase=true, editableByBPM=true, bounce=false, phaseMult=0.025, bpmMult=1, category='movement', parameter='Tilt', phaseSelection='fixturePhase', waveform='Sine', callback=callbacks.regularMovement},
        {name='Effect_16', editableByPhase=true, editableByBPM=true, bounce=false, phaseMult=0.075, bpmMult=1, category='movement', parameter='Tilt', phaseSelection='fixturePhase', waveform='Sine', callback=callbacks.secondaryMovement},
        {name='Effect_12', editableByPhase=true, editableByBPM=true, bounce=false, phaseMult=0.025, bpmMult=1, category='movement', parameter='Tilt', phaseSelection='fixturePhase', waveform='Cosine', callback=callbacks.regularMovement},
        {name='Effect_17', editableByPhase=true, editableByBPM=true, bounce=false, phaseMult=0.075, bpmMult=1, category='color', parameter='Color', phaseSelection='phase', waveform='Sine', callback=callbacks.colorCallback}    
})


return {Effect, EffectController, Effects}

